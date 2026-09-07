// Script để clear toàn bộ localStorage/SharedPreferences
// Chạy trong Chrome DevTools Console

console.log('🧹 Clearing all app data...');

// Clear localStorage
localStorage.clear();

// Clear sessionStorage
sessionStorage.clear();

console.log('✅ All data cleared! Please refresh the page and login again.');
console.log('📝 Note: You need to login again with correct credentials.');
