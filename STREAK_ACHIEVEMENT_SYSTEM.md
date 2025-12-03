# Streak & Achievement System - Documentation

## Overview
Comprehensive gamification system with daily login streaks, XP rewards, achievement badges, and leaderboards.

## Features Implemented

### 1. **Daily Login Streak System**
- Tracks consecutive daily logins
- Automatically updates streak on check-in
- Records longest streak achieved
- Breaks streak if user misses a day
- Stores complete login history

**XP Rewards:**
- Daily login: 10 XP
- 7-day milestone: 50 XP
- 30-day milestone: 200 XP

### 2. **XP & Leveling System**
- 100 XP per level
- Multiple sources of XP:
  - Daily check-in
  - Completing lessons
  - Completing exercises
  - Earning achievements
  - Learning vocabulary/grammar/kanji
- XP history tracking with reasons
- Visual progress bar to next level

### 3. **Achievement System**
**Categories:**
- **Streak** (🔥): Login streak milestones
- **Vocabulary** (📚): Word count achievements
- **Grammar** (📝): Grammar points learned
- **Kanji** (🈯): Kanji characters mastered
- **Lesson** (📖): Lesson completion milestones
- **XP** (⭐): Total XP milestones
- **Practice** (🎯): Exercise completion count

**Rarity Tiers:**
- **Common** (Gray): Easy to achieve
- **Rare** (Blue): Moderate difficulty
- **Epic** (Purple): Challenging goals
- **Legendary** (Gold): Ultimate achievements

**Total Achievements:** 27 pre-defined achievements

### 4. **Leaderboard System**
- Real-time rankings based on total XP
- Time period filters:
  - All time
  - This month
  - This week
- Shows user's current rank
- Top 3 get special visual treatment (medals)
- Displays streak and level for each user

## Backend Structure

### Models

#### UserStreak (model/UserStreak.js)
```javascript
{
  user: ObjectId,
  current_streak: Number,
  longest_streak: Number,
  last_login_date: Date,
  total_xp: Number,
  level: Number,
  login_dates: [Date],
  xp_history: [{
    amount: Number,
    reason: String,
    earned_at: Date
  }]
}
```

**Methods:**
- `updateStreak()` - Updates streak on login
- `addXP(amount, reason)` - Adds XP with reason

#### Achievement (model/Achievement.js)
```javascript
{
  name: String,
  name_vi: String,
  description: String,
  description_vi: String,
  icon: String,
  category: Enum,
  requirement_type: Enum,
  requirement_value: Number,
  xp_reward: Number,
  rarity: Enum,
  is_active: Boolean
}
```

#### UserAchievement (model/UserAchievement.js)
```javascript
{
  user: ObjectId,
  achievement: ObjectId,
  earned_at: Date,
  progress: Number,
  is_completed: Boolean
}
```

### API Endpoints

#### Streak Routes (/api/streak)
- `GET /my-streak` - Get current user's streak info
- `POST /check-in` - Daily check-in, updates streak
- `POST /add-xp` - Manually add XP (called by other features)
- `GET /xp-history` - Get XP earning history
- `GET /leaderboard?period=all&limit=50` - Get leaderboard

#### Achievement Routes (/api/achievement)
- `GET /all` - Get all active achievements
- `GET /my-achievements` - Get user's achievements with progress
- `GET /category/:category` - Get achievements by category
- `POST /update-progress` - Update achievement progress
- `GET /stats` - Get achievement statistics
- `POST /create` - Create achievement (admin)

## Frontend Structure

### Models
- `user_streak.dart` - UserStreak, XPHistory
- `achievement.dart` - Achievement, UserAchievement
- `leaderboard.dart` - LeaderboardEntry

### Services
- `streak_service.dart` - API calls for streak operations
- `achievement_service.dart` - API calls for achievements

### Providers
- `streak_provider.dart` - State management for streaks
- `achievement_provider.dart` - State management for achievements

### Screens
- `streak_screen.dart` - Main streak & XP display
- `achievement_screen.dart` - Achievement gallery with tabs
- `leaderboard_screen.dart` - Global rankings

## UI Components

### Home Screen Updates
- **Quick Stats Cards:**
  - Current streak display (🔥 X ngày)
  - Total XP display (⭐ X XP)
  - Clickable to navigate to StreakScreen
  
- **New Menu Item:**
  - "Streak & Thành tích" card
  - Direct access to streak/achievement system

### Streak Screen
- **Streak Card:**
  - Large flame emoji + current streak
  - Longest streak record
  - Check-in button (disabled if already checked in today)
  - Gradient background (red-orange)

- **XP Card:**
  - Current level display
  - Total XP count
  - Progress bar to next level
  - Gradient background (purple-blue)

- **Stats Cards:**
  - Total learning days
  - Average days per week

- **XP History:**
  - Recent XP earnings
  - Reason for each XP gain
  - Relative time display

### Achievement Screen
- **Tabs by Category:**
  - All, Vocabulary, Grammar, Kanji, Lesson, Streak, XP, Practice

- **Stats Header:**
  - Total achievements earned
  - Completion percentage
  - Locked achievements count

- **Achievement Cards:**
  - Icon and title
  - Description in Vietnamese
  - Progress bar (for incomplete)
  - Completion badge (for completed)
  - Rarity badge with color coding
  - Gradient background for completed

### Leaderboard Screen
- **User Rank Card:**
  - Highlighted display of user's rank
  - Sticky at top

- **Period Filter:**
  - All time / This month / This week
  - Dropdown menu in app bar

- **Leaderboard Entries:**
  - Rank badge (medals for top 3)
  - User avatar/initial
  - Username
  - Current streak chip
  - Level chip
  - Total XP
  - Gradient background for top 3

## Integration with Other Features

### Lesson Progress Integration
When lesson completed:
```dart
await streakProvider.addXP(50, 'Completed lesson: $lessonName');
await achievementProvider.updateProgress(lessonAchievementId, completedCount);
```

### Exercise Integration
When exercise completed:
```dart
await streakProvider.addXP(20, 'Completed exercise: $exerciseName');
await achievementProvider.updateProgress(practiceAchievementId, exerciseCount);
```

### Vocabulary/Grammar/Kanji Integration
When item learned:
```dart
await streakProvider.addXP(5, 'Learned vocabulary: $word');
await achievementProvider.updateProgress(vocabAchievementId, learnedCount);
```

## Setup Instructions

### 1. Backend Setup

**Seed Achievements:**
```bash
cd BackEnd
node scripts/seedAchievements.js
```

This will:
- Clear existing achievements
- Insert 27 pre-defined achievements
- Display summary by category

**Start Server:**
```bash
npm run dev
```

### 2. Frontend Setup

**Install Dependencies:**
```bash
cd FrontEnd
flutter pub get
```

**Run App:**
```bash
flutter run -d chrome
```

### 3. Test the System

**Test Daily Check-in:**
1. Open app and login
2. Navigate to "Streak & Thành tích"
3. Click "Check-in hôm nay"
4. Verify streak increments and XP awarded
5. Check button disables after check-in

**Test Achievements:**
1. Click trophy icon in streak screen
2. View all achievements
3. Check progress bars on incomplete achievements
4. Navigate between category tabs

**Test Leaderboard:**
1. Click leaderboard icon in streak screen
2. View global rankings
3. Switch time periods (week/month/all)
4. Verify your rank displays correctly

## XP Award Recommendations

Suggested XP values for different activities:

| Activity | XP Award |
|----------|----------|
| Daily login | 10 |
| 7-day streak | 50 |
| 30-day streak | 200 |
| Learn vocabulary | 5 |
| Learn grammar | 10 |
| Learn kanji | 15 |
| Complete exercise | 20 |
| Complete lesson | 50 |
| Perfect exercise score | +10 bonus |
| Achievement earned | Varies (100-3000) |

## Auto-Achievement Checking

The system automatically checks for achievements:

**Streak Achievements:**
- Checked on every check-in
- Compares current_streak and longest_streak

**XP Achievements:**
- Checked when XP is added
- Compares total_xp with milestones

**Activity Achievements:**
- Must be manually updated when activities complete
- Example: After lesson completion, call achievement update

## Future Enhancements

### Planned Features
1. **Weekly Challenges:**
   - Time-limited goals (e.g., "Learn 50 words this week")
   - Bonus XP rewards
   - Countdown timers

2. **Friend System:**
   - Add friends
   - Compare progress
   - Friend leaderboard

3. **Badges & Titles:**
   - Earn special titles (e.g., "Vocabulary Master")
   - Display on profile
   - Unlock at achievement milestones

4. **Streak Freeze:**
   - Allow 1-2 "freeze days" per month
   - Prevents streak loss if miss a day
   - Purchase with XP or premium

5. **Daily Quests:**
   - 3 random daily tasks
   - Bonus XP for completing all
   - Refresh at midnight

6. **Achievement Showcase:**
   - Pin favorite achievements to profile
   - Share achievements on social media
   - Achievement completion notifications

7. **Level Perks:**
   - Unlock features at certain levels
   - Special themes/avatars
   - Bonus XP multipliers

8. **Seasonal Events:**
   - Special limited-time achievements
   - Holiday-themed rewards
   - Exclusive icons/badges

## Troubleshooting

### Streak not updating
- Verify backend is running
- Check MongoDB connection
- Ensure user is authenticated
- Check browser console for errors

### Achievements not unlocking
- Run seedAchievements.js script
- Verify achievement requirements
- Check UserAchievement collection
- Ensure progress update calls are made

### Leaderboard empty
- Verify other users have XP
- Check aggregation query in backend
- Ensure period filter is correct
- Try "All time" period first

### XP not adding
- Check API response in Network tab
- Verify UserStreak record exists
- Check backend logs for errors
- Ensure amount is positive number

## Database Queries

**Find user's streak:**
```javascript
db.userstreaks.findOne({ user: ObjectId("userId") })
```

**List all achievements:**
```javascript
db.achievements.find({ is_active: true }).sort({ category: 1 })
```

**User's completed achievements:**
```javascript
db.userachievements.find({ 
  user: ObjectId("userId"),
  is_completed: true 
}).populate('achievement')
```

**Top 10 leaderboard:**
```javascript
db.userstreaks.find()
  .sort({ total_xp: -1 })
  .limit(10)
  .populate('user', 'username')
```

## Testing Checklist

- [ ] Daily check-in works
- [ ] Streak increments correctly
- [ ] Streak breaks after missing day
- [ ] XP is awarded properly
- [ ] Level increases at 100 XP intervals
- [ ] XP history displays correctly
- [ ] Achievements unlock automatically
- [ ] Progress bars show correct values
- [ ] Leaderboard sorts by XP
- [ ] User rank displays correctly
- [ ] Period filters work (week/month/all)
- [ ] Achievement categories display correctly
- [ ] Rarity colors show properly
- [ ] Top 3 get medal icons
- [ ] Stats cards show real data on home screen
- [ ] Navigation to streak screen works
- [ ] Check-in button disables after use
- [ ] Completed achievements have gradient background

## API Response Examples

**Check-in Response:**
```json
{
  "streak": 5,
  "longest_streak": 7,
  "xp_earned": 10,
  "total_xp": 450,
  "level": 5
}
```

**Leaderboard Response:**
```json
{
  "leaderboard": [
    {
      "rank": 1,
      "user": { "username": "user1", "full_name": "User One" },
      "total_xp": 5000,
      "level": 50,
      "current_streak": 30,
      "longest_streak": 45
    }
  ],
  "user_rank": 15
}
```

**My Achievements Response:**
```json
{
  "earned": [...],
  "locked": [...],
  "total": 27,
  "completed": 8
}
```

## Success! 🎉

The Streak & Achievement System is now fully implemented and ready to use!
