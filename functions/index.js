const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const { initializeApp } = require('firebase-admin/app');
const { FieldValue, getFirestore } = require('firebase-admin/firestore');

initializeApp();
const db = getFirestore();

exports.aggregateWorkerRatingOnReviewCreate = onDocumentCreated(
  'reviews/{reviewId}',
  async (event) => {
    const reviewRef = event.data?.ref;
    const reviewId = event.params.reviewId;

    if (!reviewRef) {
      logger.error('Missing review snapshot in onCreate event.', { reviewId });
      return;
    }

    await db.runTransaction(async (tx) => {
      const reviewSnap = await tx.get(reviewRef);
      if (!reviewSnap.exists) return;

      const reviewData = reviewSnap.data() || {};
      if (reviewData.aggregateApplied === true) return;

      const workerId = asString(reviewData.workerId);
      const rating = normalizeRating(reviewData.rating);

      if (!workerId || rating == null) {
        logger.error('Invalid review payload for aggregation.', {
          reviewId,
          workerId: reviewData.workerId,
          rating: reviewData.rating,
        });
        tx.update(reviewRef, {
          aggregateApplied: false,
          aggregateError: 'INVALID_REVIEW_PAYLOAD',
          aggregateAttemptedAt: FieldValue.serverTimestamp(),
        });
        return;
      }

      const workerRef = db.collection('workers').doc(workerId);
      const workerSnap = await tx.get(workerRef);
      if (!workerSnap.exists) {
        logger.error('Worker not found for review aggregation.', {
          reviewId,
          workerId,
        });
        tx.update(reviewRef, {
          aggregateApplied: false,
          aggregateError: 'WORKER_NOT_FOUND',
          aggregateAttemptedAt: FieldValue.serverTimestamp(),
        });
        return;
      }

      const workerData = workerSnap.data() || {};
      const oldCount = asInt(workerData.ratingCount ?? workerData.reviewCount);
      const explicitSum = asNumber(workerData.ratingSum, null);
      const oldAvg = asNumber(workerData.ratingAvg ?? workerData.rating, 0);
      const oldSum = explicitSum == null ? oldAvg * oldCount : explicitSum;

      const newCount = oldCount + 1;
      const newSum = oldSum + rating;
      const newAvg = round2(newSum / newCount);

      tx.set(
        workerRef,
        {
          ratingSum: newSum,
          ratingCount: newCount,
          ratingAvg: newAvg,
          rating: newAvg,
          reviewCount: newCount,
          updated_at: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      tx.update(reviewRef, {
        aggregateApplied: true,
        aggregateAppliedAt: FieldValue.serverTimestamp(),
        aggregateAttemptedAt: FieldValue.serverTimestamp(),
        aggregateError: FieldValue.delete(),
      });
    });
  },
);

function normalizeRating(value) {
  const n = asNumber(value, null);
  if (n == null) return null;
  if (n < 1 || n > 5) return null;
  return n;
}

function asString(value) {
  if (typeof value !== 'string') return '';
  return value.trim();
}

function asInt(value, fallback = 0) {
  if (typeof value === 'number' && Number.isFinite(value)) return Math.trunc(value);
  const parsed = Number.parseInt(`${value}`, 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function asNumber(value, fallback = 0) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  const parsed = Number.parseFloat(`${value}`);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function round2(value) {
  return Math.round(value * 100) / 100;
}
