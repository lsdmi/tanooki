# Session Debugging System Guide

## 🎯 **Overview**

This comprehensive session debugging system has been implemented to help track and diagnose session-related issues, particularly the problem where normal sessions are being returned as broken without Warden authentication keys.

## 🔧 **What's Been Added**

### **1. Entry Checks (Before Each Request)**
- **`SESSION_ENTRY_CHECK`** - Logs session state at request start
- **`MIDDLEWARE_ENTRY`** - Logs incoming cookies and session data
- **`WARDEN_ENTRY`** - Logs authentication events
- **`COOKIE_ENTRY`** - Detailed cookie analysis and decryption

### **2. Exit Checks (After Each Request)**
- **`SESSION_EXIT_CHECK`** - Logs final session state after request
- **`MIDDLEWARE_EXIT`** - Logs response cookies and session state
- **`WARDEN_EXIT`** - Logs final authentication state
- **`COOKIE_EXIT`** - Detailed exit analysis and corruption detection

### **3. Key Features**
- **Session ID Tracking** - Every log entry includes session ID for correlation
- **Request ID Correlation** - Track individual requests through the system
- **User ID Tracking** - `debug_user_id` added to session for better user tracking
- **Warden Key Monitoring** - Tracks `warden.user.user.key` and other authentication keys
- **Cookie Corruption Detection** - Detects suspiciously short cookies (≤50 chars vs normal 900+ chars)
- **Session State Validation** - Checks for empty sessions and authentication inconsistencies
- **Session Corruption Detection** - Detects when user_id is present but Warden keys are missing
- **Enhanced User Object Logging** - Shows detailed user information including class, inspect output, and Warden user objects

## 🚀 **How to Use**

### **1. Start Your Rails Server**
```bash
bin/dev
```

### **2. Monitor Session Logs in Real-Time**
```bash
bin/rails session:monitor
```
This will show session-related log messages as they happen. Press `Ctrl+C` to stop.

### **3. Check Recent Session Logs**
```bash
bin/rails session:recent
```
Shows the last 100 lines of session-related log entries.

### **4. Test the Logging System**
```bash
bin/rails session:test_logging
```
Makes a test request to verify the logging is working.

### **5. Check Session Configuration**
```bash
bin/rails session:debug
```
Shows current session store configuration and settings.

## 📊 **What to Look For**

### **Normal Guest User Session**
```
SESSION_ENTRY_CHECK: Session ID: abc123, Authenticated: false, Debug User ID: 
SESSION_ENTRY_CHECK: All session keys: session_id, pokemon_catch_last_seen, pokemon_guest_caught
SESSION_EXIT_CHECK: Session ID: abc123, Authenticated: false, Debug User ID: 
SESSION_EXIT_CHECK: All session keys: session_id, pokemon_catch_last_seen, pokemon_guest_caught
```

### **Normal Authenticated User Session**
```
SESSION_ENTRY_CHECK: Session ID: def456, User ID: 1, Authenticated: true, Debug User ID: 1
SESSION_ENTRY_CHECK: User details - ID: 1, Email: user@example.com, Class: User
SESSION_ENTRY_CHECK: User object inspect: #<User id: 1, email: "user@example.com", ...>
SESSION_ENTRY_CHECK: ✅ Warden authentication keys present: warden.user.user.key
SESSION_ENTRY_CHECK: Warden user object - ID: 1, Email: user@example.com, Class: User
SESSION_EXIT_CHECK: Session ID: def456, User ID: 1, Authenticated: true, Debug User ID: 1
SESSION_EXIT_CHECK: User details - ID: 1, Email: user@example.com, Class: User
SESSION_EXIT_CHECK: ✅ Warden authentication keys present: warden.user.user.key
```

### **Broken Session (The Problem You're Investigating)**
```
SESSION_ENTRY_CHECK: Session ID: ghi789, User ID: 1, Authenticated: true, Debug User ID: 1
SESSION_ENTRY_CHECK: User details - ID: 1, Email: user@example.com, Class: User
SESSION_ENTRY_CHECK: ✅ Warden authentication keys present: warden.user.user.key
SESSION_EXIT_CHECK: Session ID: ghi789, User ID: , Authenticated: false, Debug User ID: 1
SESSION_EXIT_CHECK: ❌ No Warden authentication keys found
```

### **Session Corruption Detection (NEW!)**
```
SESSION_EXIT_CHECK: 🚨 SESSION CORRUPTION DETECTED - User ID present (1) but NO Warden keys! Session ID: abc123
SESSION_EXIT_CHECK: This indicates the session was corrupted or Warden keys were lost during request processing
SESSION_EXIT_CHECK: 🔍 CORRUPTED SESSION ANALYSIS:
SESSION_EXIT_CHECK: - User should be authenticated but Warden keys are missing
SESSION_EXIT_CHECK: - Possible causes:
SESSION_EXIT_CHECK:   * Warden keys were cleared during request processing
SESSION_EXIT_CHECK:   * Session store corruption
SESSION_EXIT_CHECK:   * Middleware interference
SESSION_EXIT_CHECK:   * Cookie corruption during transmission
SESSION_EXIT_CHECK:   * Session serialization/deserialization error
```

### **User ID Mismatch Detection**
```
SESSION_EXIT_CHECK: ⚠️ USER ID MISMATCH - Debug User ID: 1, Current User ID: 2, Session ID: abc123
```

### **Corrupted Cookie Detection**
```
SESSION_EXIT_CHECK: ⚠️ SUSPICIOUS SHORT COOKIE - Length: 19 (normal cookies are 900+ chars)
SESSION_EXIT_CHECK: Full cookie value: test_session_cookie
```

### **Enhanced User Object Information (NEW!)**
```
SESSION_ENTRY_CHECK: User details - ID: 1, Email: user@example.com, Class: User
SESSION_ENTRY_CHECK: User object inspect: #<User id: 1, email: "user@example.com", encrypted_password: "[FILTERED]", ...>
SESSION_ENTRY_CHECK: Warden user object - ID: 1, Email: user@example.com, Class: User
[WARDEN_ENTRY] User object details - Class: User, Inspect: #<User id: 1, email: "user@example.com", ...>
```

## 🔍 **Debugging Your Specific Issue**

### **1. Look for Session ID Changes**
If the session ID changes between entry and exit, that indicates a new session was created.

### **2. Check for Warden Key Disappearance**
Look for patterns where Warden keys are present at entry but missing at exit.

### **3. Monitor User ID Consistency**
The `debug_user_id` should remain consistent throughout the session. If it changes or becomes nil, that indicates a session issue.

### **4. Monitor Cookie Length**
Normal session cookies should be 900+ characters. Short cookies (≤50 chars) indicate corruption.

### **5. Track Request Flow**
Use the Request ID to follow a single request through all the logging layers.

### **6. Watch for Session Corruption (NEW!)**
The system now specifically detects when a user_id is present but Warden keys are missing, which is exactly the issue you're experiencing.

### **7. Analyze User Object Details (NEW!)**
The enhanced logging now shows:
- **User ID**: `current_user.id` - Database user ID
- **User Email**: `current_user.email` - User's email address
- **User Class**: `current_user.class` - Ruby class (should be `User`)
- **User Object Inspect**: Full object inspection for debugging
- **Warden User Object**: Details about the user object stored in Warden
- **Debug User ID**: `session[:debug_user_id]` - Our tracking ID

## 📝 **Example Log Analysis**

Here's what a typical log entry looks like with enhanced user object logging:

```
MIDDLEWARE_ENTRY: Request started - Path: /, Method: GET, Request ID: req-123
COOKIE_ENTRY: [1] Cookie check - Session ID: abc123, Request ID: req-123
COOKIE_ENTRY: [3] ✅ Found Warden authentication keys: warden.user.user.key
SESSION_ENTRY_CHECK: Authentication check - Controller: home, Action: index, Session ID: abc123, User ID: 1, Authenticated: true, Debug User ID: 1
SESSION_ENTRY_CHECK: User details - ID: 1, Email: user@example.com, Class: User
SESSION_ENTRY_CHECK: User object inspect: #<User id: 1, email: "user@example.com", encrypted_password: "[FILTERED]", ...>
SESSION_ENTRY_CHECK: ✅ Warden authentication keys present: warden.user.user.key
SESSION_ENTRY_CHECK: Warden user object - ID: 1, Email: user@example.com, Class: User
WARDEN_ENTRY: User set in session - ID: 1, Email: user@example.com, Session ID: abc123, Debug User ID: 1
WARDEN_ENTRY: User object details - Class: User, Inspect: #<User id: 1, email: "user@example.com", ...>

# ... request processing ...

SESSION_EXIT_CHECK: Session exit state - Controller: home, Action: index, Session ID: abc123, User ID: 1, Authenticated: true, Debug User ID: 1
SESSION_EXIT_CHECK: User details - ID: 1, Email: user@example.com, Class: User
SESSION_EXIT_CHECK: ✅ Warden authentication keys present: warden.user.user.key
MIDDLEWARE_EXIT: Response cookies set - Count: 1, Request ID: req-123
MIDDLEWARE_EXIT: ✅ Response cookie has Warden keys: warden.user.user.key
MIDDLEWARE_EXIT: Debug User ID in response cookie: 1
COOKIE_EXIT: [2] ✅ Warden keys at exit: warden.user.user.key
```

## 🚨 **Critical Issues to Watch For**

### **1. Empty Sessions**
```
COOKIE_ENTRY: [3] 🚨 BROKEN SESSION - Empty session keys (should have at least session_id)
```

### **2. Missing Warden Keys**
```
SESSION_EXIT_CHECK: ❌ No Warden authentication keys found - Session ID: abc123
```

### **3. Session Corruption (NEW!)**
```
SESSION_EXIT_CHECK: 🚨 SESSION CORRUPTION DETECTED - User ID present (1) but NO Warden keys! Session ID: abc123
```

### **4. User ID Mismatch**
```
SESSION_EXIT_CHECK: ⚠️ USER ID MISMATCH - Debug User ID: 1, Current User ID: 2, Session ID: abc123
```

### **5. Short Cookies**
```
SESSION_EXIT_CHECK: ⚠️ SUSPICIOUS SHORT COOKIE - Length: 19 (normal cookies are 900+ chars)
```

### **6. Authentication Mismatch**
```
COOKIE_EXIT: [3] ❌ User NOT authenticated at exit despite cookie - Session ID: abc123
```

### **7. User Object Issues (NEW!)**
```
SESSION_ENTRY_CHECK: User details - ID: 1, Email: user@example.com, Class: User
# If Class is not User, or inspect shows unexpected data, this indicates an issue
```

## 🎯 **Next Steps**

1. **Start monitoring** with `bin/rails session:monitor`
2. **Make some requests** to your application (login, browse pages, etc.)
3. **Look for patterns** where sessions start good but end broken
4. **Check for user_id consistency** - the debug_user_id should remain the same
5. **Check for suspicious short cookies** that might indicate corruption
6. **Track session ID changes** to see if new sessions are being created unexpectedly
7. **Watch for session corruption detection** - this will specifically catch your issue
8. **Analyze user object details** - check if the user object is correct and complete

## 🔧 **Enhanced User Object Logging Feature**

The system now provides detailed information about user objects at every stage:

### **What's Logged:**
- **User ID**: Database primary key
- **User Email**: User's email address
- **User Class**: Ruby class (should be `User`)
- **User Object Inspect**: Full object inspection for debugging
- **Warden User Object**: Details about the user object stored in Warden session
- **Debug User ID**: Our tracking ID for session correlation

### **Why This Helps:**
- **Identify user object corruption** - if the user object is incomplete or wrong class
- **Track user identity changes** - see if the user switches during a request
- **Debug Warden issues** - see what Warden actually stores vs what we expect
- **Session correlation** - track the same user across multiple requests

This enhanced logging will help you identify exactly where and when sessions are losing their Warden authentication keys, which appears to be the core issue you're experiencing. 