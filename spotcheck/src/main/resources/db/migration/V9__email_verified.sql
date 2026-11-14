-- Registration never checks the email. Google sign-in proves it: the first time Google signs into an
-- account whose email was not proven yet, the password and old sessions are dropped (someone else may
-- have registered with that address), and the email counts as verified from then on.
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT FALSE;
