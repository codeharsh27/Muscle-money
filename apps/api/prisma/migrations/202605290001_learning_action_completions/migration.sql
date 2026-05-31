CREATE TABLE "learning_action_completions" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "lessonId" UUID NOT NULL,
    "actionKey" TEXT NOT NULL,
    "actionType" TEXT NOT NULL,
    "amountMinor" INTEGER,
    "note" TEXT,
    "metadata" JSONB,
    "completedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "learning_action_completions_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "learning_action_completions_userId_lessonId_actionKey_key" ON "learning_action_completions"("userId", "lessonId", "actionKey");
CREATE INDEX "learning_action_completions_userId_completedAt_idx" ON "learning_action_completions"("userId", "completedAt");

ALTER TABLE "learning_action_completions"
ADD CONSTRAINT "learning_action_completions_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "learning_action_completions"
ADD CONSTRAINT "learning_action_completions_lessonId_fkey"
FOREIGN KEY ("lessonId") REFERENCES "lessons"("id") ON DELETE CASCADE ON UPDATE CASCADE;
