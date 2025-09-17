# Beaver

Habit tracking application.

## Environment Variables

- `FIRST_DAY_OF_WEEK`: First day of week
- `HABITS_STORAGE`: Storage path
- `MAX_USER_COUNT`: Max users
- `INDEX_SHOW_HABIT_COUNT`: Show habit count
- `ENABLE_IOS_STANDALONE`: iOS standalone mode
- `TRUSTED_LOCAL_EMAIL`: Trusted email

## Setup

1. Set env vars in `.env`
2. Run: `systemctl --user start beaver.container`