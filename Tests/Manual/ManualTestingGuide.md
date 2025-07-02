# NookNote Manual Testing Guide

This guide provides comprehensive manual testing scenarios to verify NookNote functionality, user experience, and edge cases.

## 🚀 Quick Start Testing

### Initial Setup Test
1. **First Launch**
   - [ ] Launch NookNote for the first time
   - [ ] Verify "Setup Required" screen appears
   - [ ] Check that app icon appears in MenuBar
   - [ ] Verify clicking MenuBar icon opens the popup

2. **Configuration Test**
   - [ ] Click "Open Settings" or press `⌘,`
   - [ ] Enter GitHub repository owner (e.g., "microsoft")
   - [ ] Enter repository name (e.g., "vscode")
   - [ ] Enter valid Personal Access Token
   - [ ] Click "Save Settings"
   - [ ] Verify main interface appears

## 🔐 Authentication Testing

### Valid Authentication
1. **Token Validation**
   - [ ] Configure with valid token and repository
   - [ ] Verify authentication succeeds
   - [ ] Check that discussions load successfully
   - [ ] Verify no error messages appear

2. **Authentication State Management**
   - [ ] Close and reopen app
   - [ ] Verify authentication state persists
   - [ ] Check that app remembers settings

### Invalid Authentication
1. **Invalid Token**
   - [ ] Enter invalid Personal Access Token
   - [ ] Verify appropriate error message appears
   - [ ] Check that error is user-friendly

2. **Insufficient Permissions**
   - [ ] Use token without discussion permissions
   - [ ] Verify permission error message
   - [ ] Check guidance for required permissions

3. **Repository Not Found**
   - [ ] Enter non-existent repository
   - [ ] Verify 404 error handling
   - [ ] Check error message clarity

## 📋 Discussions List Testing

### Loading Discussions
1. **Initial Load**
   - [ ] Open authenticated app
   - [ ] Verify discussions load automatically
   - [ ] Check loading indicator appears and disappears
   - [ ] Verify discussion count is accurate

2. **Refresh Functionality**
   - [ ] Press `⌘R` or click refresh
   - [ ] Verify discussions reload
   - [ ] Check that new discussions appear if available
   - [ ] Verify refresh doesn't duplicate existing discussions

3. **Pagination**
   - [ ] If repository has >20 discussions, verify pagination
   - [ ] Scroll to bottom and load more
   - [ ] Check that additional discussions load
   - [ ] Verify no duplicate discussions

### Discussion Display
1. **Discussion Information**
   - [ ] Verify title displays correctly
   - [ ] Check author information is shown
   - [ ] Verify creation date is formatted properly
   - [ ] Check comment count accuracy
   - [ ] Verify category badge appears

2. **Discussion States**
   - [ ] Test with open discussions
   - [ ] Test with closed discussions
   - [ ] Test with locked discussions
   - [ ] Verify state indicators are clear

## ✏️ New Post Testing

### Creating Discussions
1. **Valid Discussion Creation**
   - [ ] Switch to "New Post" tab or press `⌘N`
   - [ ] Select discussion category
   - [ ] Enter discussion title
   - [ ] Enter discussion body (test Markdown support)
   - [ ] Press `⌘⏎` or click "Post Discussion"
   - [ ] Verify discussion is created and appears in list

2. **Form Validation**
   - [ ] Try to submit with empty title
   - [ ] Verify validation error appears
   - [ ] Try to submit with only whitespace
   - [ ] Check that validation catches edge cases

3. **Markdown Support**
   - [ ] Test basic Markdown (bold, italic, links)
   - [ ] Test code blocks
   - [ ] Test lists and headers
   - [ ] Verify preview functionality if available

### Error Handling
1. **Network Errors**
   - [ ] Disconnect from internet
   - [ ] Try to create discussion
   - [ ] Verify appropriate error message
   - [ ] Reconnect and verify retry works

2. **API Errors**
   - [ ] Test with rate-limited token
   - [ ] Verify rate limit error handling
   - [ ] Test with expired token
   - [ ] Check token refresh prompts

## 🖱️ User Interface Testing

### Navigation
1. **Tab Switching**
   - [ ] Click between "Discussions" and "New Post" tabs
   - [ ] Use `⌃⇥` keyboard shortcut
   - [ ] Verify smooth transitions
   - [ ] Check tab state persistence

2. **Modal Dialogs**
   - [ ] Open Settings dialog with `⌘,`
   - [ ] Close with `⌘W` or Escape
   - [ ] Open Discussion Details
   - [ ] Verify focus management

3. **MenuBar Integration**
   - [ ] Click MenuBar icon to show/hide
   - [ ] Click outside popup to dismiss
   - [ ] Verify popup position on different screens
   - [ ] Test with multiple monitors

### Keyboard Shortcuts
1. **Test All Shortcuts**
   - [ ] `⌘N` - New discussion
   - [ ] `⌘R` - Refresh discussions
   - [ ] `⌘L` - Toggle filters
   - [ ] `⌘F` - Focus search
   - [ ] `⌘K` - Clear form/search
   - [ ] `⌘W` - Close window
   - [ ] `⌘,` - Open settings
   - [ ] `⌘⏎` - Post (in editor)
   - [ ] `⎋` - Cancel/close
   - [ ] `⌃⇥` - Switch tabs

2. **Keyboard Navigation**
   - [ ] Tab through all interactive elements
   - [ ] Verify focus indicators are visible
   - [ ] Check that tab order is logical
   - [ ] Test with VoiceOver enabled

### Responsive Design
1. **Window Sizing**
   - [ ] Test at minimum window size
   - [ ] Test at maximum window size
   - [ ] Resize window and verify content adapts
   - [ ] Check that text remains readable

2. **Content Scaling**
   - [ ] Change system text size
   - [ ] Verify interface scales appropriately
   - [ ] Check that buttons remain tappable
   - [ ] Verify no content is cut off

## 🎨 Visual and Animation Testing

### Design System
1. **Colors and Themes**
   - [ ] Verify colors match design system
   - [ ] Test in light mode
   - [ ] Test in dark mode
   - [ ] Check high contrast mode

2. **Typography**
   - [ ] Verify font sizes are appropriate
   - [ ] Check font weights and styles
   - [ ] Test with different system fonts
   - [ ] Verify text remains readable

3. **Animations**
   - [ ] Test tab switching animations
   - [ ] Verify loading animations
   - [ ] Check hover state transitions
   - [ ] Test with "Reduce Motion" enabled

### Loading States
1. **Progress Indicators**
   - [ ] Verify loading spinners appear during API calls
   - [ ] Check skeleton UI for loading states
   - [ ] Test loading timeout handling
   - [ ] Verify loading states are accessible

2. **Empty States**
   - [ ] Test with repository with no discussions
   - [ ] Verify empty state message is helpful
   - [ ] Check empty state styling
   - [ ] Test empty state actions

## 🚨 Error Handling Testing

### Network Issues
1. **Connection Problems**
   - [ ] Test with no internet connection
   - [ ] Test with slow internet connection
   - [ ] Test with intermittent connectivity
   - [ ] Verify appropriate error messages

2. **API Issues**
   - [ ] Test with invalid API endpoints
   - [ ] Test with malformed responses
   - [ ] Test timeout scenarios
   - [ ] Verify error recovery mechanisms

### Authentication Issues
1. **Token Problems**
   - [ ] Test with expired token
   - [ ] Test with revoked token
   - [ ] Test with malformed token
   - [ ] Verify re-authentication prompts

2. **Permission Issues**
   - [ ] Test with read-only permissions
   - [ ] Test with insufficient scopes
   - [ ] Verify permission upgrade prompts
   - [ ] Check permission error messages

### Application Errors
1. **Unexpected Errors**
   - [ ] Test with corrupted settings
   - [ ] Test with invalid data formats
   - [ ] Verify graceful error handling
   - [ ] Check error reporting mechanisms

## 🔧 Settings Testing

### Configuration Management
1. **Settings Persistence**
   - [ ] Configure settings and restart app
   - [ ] Verify settings are saved
   - [ ] Test settings import/export
   - [ ] Check settings validation

2. **Settings Changes**
   - [ ] Change repository while app is running
   - [ ] Verify app adapts to new settings
   - [ ] Test invalid setting combinations
   - [ ] Check setting change notifications

### Advanced Settings
1. **Refresh Intervals**
   - [ ] Test different auto-refresh intervals
   - [ ] Verify refresh behavior
   - [ ] Test disabling auto-refresh
   - [ ] Check manual refresh still works

2. **Notification Settings**
   - [ ] Enable/disable notifications
   - [ ] Test notification permissions
   - [ ] Verify notification behavior
   - [ ] Check notification content

## 🔍 Edge Cases Testing

### Data Edge Cases
1. **Large Data Sets**
   - [ ] Test with repository with 1000+ discussions
   - [ ] Verify pagination works correctly
   - [ ] Check performance with large lists
   - [ ] Test memory usage

2. **Special Characters**
   - [ ] Test with unicode characters in titles
   - [ ] Test with emoji in content
   - [ ] Test with special markdown characters
   - [ ] Verify proper encoding/decoding

3. **Long Content**
   - [ ] Test with very long discussion titles
   - [ ] Test with large discussion bodies
   - [ ] Test with long usernames
   - [ ] Verify text truncation/wrapping

### Timing Edge Cases
1. **Race Conditions**
   - [ ] Rapidly switch between tabs
   - [ ] Quickly open/close dialogs
   - [ ] Rapid refresh requests
   - [ ] Verify state consistency

2. **Timeout Scenarios**
   - [ ] Test with very slow API responses
   - [ ] Test timeout handling
   - [ ] Verify timeout error messages
   - [ ] Check retry mechanisms

## 📱 Accessibility Testing

### VoiceOver Testing
1. **Screen Reader Support**
   - [ ] Enable VoiceOver
   - [ ] Navigate through entire interface
   - [ ] Verify all elements are announced
   - [ ] Check announcement clarity

2. **Accessibility Labels**
   - [ ] Verify all buttons have labels
   - [ ] Check that labels are descriptive
   - [ ] Test with different voice settings
   - [ ] Verify context is provided

### Motor Accessibility
1. **Keyboard Only**
   - [ ] Navigate entire app using only keyboard
   - [ ] Verify all functions are accessible
   - [ ] Check focus management
   - [ ] Test tab order logic

2. **Switch Control**
   - [ ] Enable Switch Control
   - [ ] Navigate through interface
   - [ ] Verify all actions are possible
   - [ ] Check timing requirements

## 📊 Performance Testing

### Response Times
1. **API Performance**
   - [ ] Measure discussion loading time
   - [ ] Test with slow network conditions
   - [ ] Verify reasonable timeouts
   - [ ] Check performance indicators

2. **UI Performance**
   - [ ] Test smooth scrolling
   - [ ] Verify responsive interactions
   - [ ] Check animation smoothness
   - [ ] Test with large data sets

### Memory Usage
1. **Memory Monitoring**
   - [ ] Monitor memory usage during normal use
   - [ ] Test for memory leaks
   - [ ] Check memory usage with large lists
   - [ ] Verify memory is released

## 🔄 Compatibility Testing

### macOS Versions
1. **System Compatibility**
   - [ ] Test on macOS 12.0 (Monterey)
   - [ ] Test on macOS 13.0 (Ventura)
   - [ ] Test on macOS 14.0 (Sonoma)
   - [ ] Verify feature compatibility

2. **Hardware Compatibility**
   - [ ] Test on Intel Macs
   - [ ] Test on Apple Silicon Macs
   - [ ] Test different screen sizes
   - [ ] Verify performance on older hardware

### GitHub Compatibility
1. **Repository Types**
   - [ ] Test with public repositories
   - [ ] Test with private repositories
   - [ ] Test with organization repositories
   - [ ] Test with repositories with no discussions

2. **API Versions**
   - [ ] Test with current GitHub API
   - [ ] Verify GraphQL compatibility
   - [ ] Test rate limiting behavior
   - [ ] Check API version handling

## 📋 Test Results Checklist

### Critical Issues (Must Fix)
- [ ] App crashes
- [ ] Data loss
- [ ] Security vulnerabilities
- [ ] Complete feature failures
- [ ] Accessibility blockers

### High Priority Issues (Should Fix)
- [ ] Poor performance
- [ ] Confusing error messages
- [ ] UI inconsistencies
- [ ] Minor accessibility issues
- [ ] Keyboard navigation problems

### Medium Priority Issues (Nice to Fix)
- [ ] Minor visual inconsistencies
- [ ] Edge case handling
- [ ] Performance optimizations
- [ ] UX improvements
- [ ] Additional keyboard shortcuts

### Low Priority Issues (Future Consideration)
- [ ] Visual polish
- [ ] Additional features
- [ ] Advanced customization
- [ ] Power user features
- [ ] Integration enhancements

## 📝 Test Reporting Template

When reporting issues, include:

1. **Issue Description**
   - What happened?
   - What was expected?
   - Steps to reproduce

2. **Environment Details**
   - macOS version
   - Hardware information
   - Network conditions
   - GitHub repository details

3. **Impact Assessment**
   - How often does this occur?
   - Who is affected?
   - Severity level

4. **Supporting Information**
   - Screenshots/videos
   - Console logs
   - Error messages
   - Performance measurements

## ✅ Testing Sign-off

Once all tests are completed:

- [ ] All critical tests pass
- [ ] High priority issues are addressed
- [ ] Performance meets requirements
- [ ] Accessibility requirements are met
- [ ] User experience is satisfactory
- [ ] Documentation is updated
- [ ] Test results are documented

**Tester:** ________________________  
**Date:** ________________________  
**Version:** ________________________  
**Status:** ________________________