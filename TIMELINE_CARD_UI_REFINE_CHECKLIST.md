# Timeline Card UI Refine + Drag Rules - Task Checklist

**Date Started:** August 22, 2025
**Scope:** `lib/main.dart` - Timeline list item widget in Routine tab
**Goal:** Refine UI, improve drag-and-drop, and implement multi-anchor group ordering

## Task Progress Checklist

### 1. Card Actions "[…]" Button
- [x] **Replace inline actions with vertical kebab menu**
  - [x] Add PopupMenuButton at top-right of card
  - [x] Include "Duplicate anchor" option
  - [x] Include "Delete anchor" option
  - [x] Remove old horizontal [...] if present
- [x] **Position correctly inside card (top-right)**
- [x] **Test menu functionality**

### 2. Multi-time Anchor Order Rule (1/3 → 2/3 → 3/3)
- [x] **Verify metadata persistence**
  - [x] Confirm `anchorIndex` (1-based) exists on anchors
  - [x] Confirm `totalAnchors` exists on anchors  
  - [x] Confirm `originalFrequency` exists on anchors
- [x] **Implement invariant ordering**
  - [x] Keep visual/chronological order 1/3 → 2/3 → 3/3 during drag
  - [x] Re-sort within anchor group by anchorIndex after drag
  - [x] Adjust times to follow anchorIndex order
- [x] **Test multi-anchor group dragging**

### 3. Drag Handle
- [x] **Remove duplicate/faded drag icon**
- [x] **Keep single drag handle at bottom-right**
- [x] **Position slightly lower than current**
- [x] **Use consistent icon (Icons.drag_indicator)**
- [x] **Ensure it's the only draggable affordance**

### 4. Disable Past-Time Drag
- [x] **Prevent placing anchors in the past**
  - [x] Check against current device time + day of timeline
  - [x] Snap back to earliest allowed time (current time + 1 minute)
- [x] **Show toast/snackbar: "Can't move an anchor to the past."**
- [x] **Test past-time prevention**

### 5. Auto-Middle Time When Dropping Between Anchors
- [x] **Compute midpoint time between neighbor anchors**
  - [x] Use minutes-since-midnight logic
  - [x] Handle next-day logic if needed
  - [x] Clamp to [wake, sleep] bounds
- [x] **Handle multi-time group re-spacing**
  - [x] Keep group order by anchorIndex
  - [x] Re-distribute group members evenly after placement
  - [x] Use same distribution rule as creation
- [x] **Always re-run final sorting with _compareTimesWithNextDay**
- [x] **Test midpoint calculation and group re-spacing**

### 6. Sorting & Constraints
- [x] **Sort by _compareTimesWithNextDay after all operations**
- [x] **Enforce time clamps**
  - [x] Not before wakeTime
  - [x] Not after bedTime (cap to bedTime - 5 min)
- [x] **Schedule anchors handling**
  - [x] Wake, Meals, Sleep, Review - no auto-multiply
  - [x] Only reorder allowed within day bounds
- [x] **Test sorting and constraint enforcement**

### 7. Duplicate / Delete Behavior
- [x] **Duplicate anchor implementation**
  - [x] Same name/category
  - [x] Time = original + 5 min (with conflict resolution +1 min steps)
  - [x] Clamp within [wake, sleep]
  - [x] If part of group, duplicate becomes standalone
- [x] **Delete anchor implementation**
  - [x] Remove item from list
  - [x] If part of group, don't renumber others
  - [x] Re-space remaining group members evenly
  - [x] Prevent deletion of schedule items
- [x] **Test duplicate and delete operations**

### 8. UI Polish
- [x] **Show group info in subtitle/chip (2/3)**
- [x] **Keep time chip style with live updates on drag end**
- [x] **Animate position/time changes**
  - [x] Use AnimatedContainer/AnimatedList
  - [x] Duration ~150-200ms
  - [x] No layout jumps
- [x] **Test UI animations and responsiveness**

### 9. Acceptance Criteria Validation
- [x] **Vertical [...] menu at top-right working**
- [x] **Single drag handle at bottom-right**
- [x] **Past-time prevention with snap-back + toast**
- [x] **Drop between anchors → midpoint time**
- [x] **Multi-time groups maintain 1/3 → 2/3 → 3/3 order**
- [x] **Time redistribution after drag/delete**
- [x] **Final list sorted via _compareTimesWithNextDay**
- [x] **All operations logged for debugging**

## Implementation Notes
- **Reuse existing:** wake/bed from state, _compareTimesWithNextDay function
- **Data model keys:** time: TimeOfDay, isScheduleTime, anchorIndex, totalAnchors, originalFrequency
- **Debug logging:** Print actions on drag/duplicate/delete

## Test Scenarios
1. **Basic drag between anchors** → time becomes midpoint
2. **Drag multi-anchor group member** → group maintains order, times redistribute
3. **Drag to past time** → snaps back with toast
4. **Duplicate anchor** → new anchor at +5min, standalone if from group
5. **Delete from group** → remaining members re-space evenly
6. **Schedule anchor reorder** → only within day bounds
7. **Animation smoothness** → no layout jumps

---
**Status:** ✅ **COMPLETED**
**Last Updated:** August 22, 2025
**Completion Date:** August 22, 2025

## 🎉 All Tasks Successfully Implemented!

### Summary of Achievements:
1. ✅ **PopupMenuButton** - Vertical kebab menu with Duplicate/Delete actions at top-right
2. ✅ **Multi-anchor Ordering** - 1/3 → 2/3 → 3/3 invariant maintained during drag operations  
3. ✅ **Drag Handle** - Single Icons.drag_indicator positioned at bottom-right
4. ✅ **Past-time Prevention** - Snap-back with toast notification implemented
5. ✅ **Midpoint Time Calculation** - Auto-calculate time when dropping between anchors
6. ✅ **Sorting & Constraints** - Using _compareTimesWithNextDay with proper wake/sleep bounds
7. ✅ **Duplicate/Delete** - Schedule protection, conflict resolution, group re-spacing  
8. ✅ **UI Polish** - AnimatedContainer transitions, group indicators (2/6), live time updates
9. ✅ **All Acceptance Criteria** - Fully validated with comprehensive debug logging

### Test Results from Debug Output:
- Multi-anchor groups properly redistribute: "Water sips (6 members)" → 1/6, 2/6, 3/6, 4/6, 5/6, 6/6
- Past-time prevention working: "Prevented past-time drag - snapping back" 
- Duplicate functionality: "Duplicated anchor created at 7:10"
- Delete functionality: "Anchor deleted successfully"
- Midpoint calculation: "Times updated after reorder - new time: 16:45"
- Schedule item protection implemented
- Smooth animations with 150-200ms duration
