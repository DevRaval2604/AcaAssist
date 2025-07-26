# AcaAssist – Object-Oriented Concept Mapping

This document outlines the core object-oriented concepts that form the foundation of the AcaAssist academic assistant app. Each object is listed along with its operational context and the key data (information) it holds.

---

## Object-Context-Information Map

### 1. `User`
- **Context:** Represents a student using the app. Central to all functionality (authentication, personalization, etc.).
- **Information:**
  - `userID`: String
  - `name`: String
  - `email`: String
  - `password`: Hashed String (stored securely)
  - `subjects`: List of Subject objects
  - `preferences`: voice settings

---

### 2. `AuthenticationService`
- **Context:** Handles user registration, login, password resets, and account management.
- **Information:**
  - `signInWithEmailAndPassword(email, password)`
  - `signInWithGoogle()`
  - `resetPassword(email)`
  - `changePassword(oldPassword, newPassword)`

---

### 3. `Task`
- **Context:** Core unit of task management, representing assignments, exams, and project deadlines.
- **Information:**
  - `taskID`: String
  - `title`: String
  - `description`: String
  - `dueDate`: Date
  - `priority`: Enum (Low/Medium/High)
  - `status`: Enum (Pending/Completed)

---

### 4. `TaskManager`
- **Context:** Business logic layer to manage tasks.
- **Information:**
  - `addTask(task)`
  - `editTask(taskID, updatedData)`
  - `deleteTask(taskID)`
  - `getTasksByUser(userID)`

---

### 5. `Subject`
- **Context:** Represents a course or subject the student is enrolled in. These subjects are linked to tasks and schedules.
- **Information:**
  - `subjectID`: String
  - `name`: String
  - `code`: String (e.g., CS101)
  - `instructorName`: String
  - `semester`: String or Int
  - `userID`: String (relation to User)

---

### 6. `StudyPlan`
- **Context:** Personalized schedule created based on task deadlines and available time.
- **Information:**
  - `planID`: String
  - `tasksMapped`: List of subjectIDs
  - `allocatedTimeSlots`: Map<DateTime, Duration>
  - `editable`: Boolean

---

### 7. `SchedulerEngine`
- **Context:** Logic engine that generates or modifies study plans.
- **Information:**
  - `generatePlan(userID)`

---

### 8. `AnalyticsEngine`
- **Context:** Compute productivity metrics.
- **Information:**
  - `generateAnalysis()`

---

### 9. `Resource`
- **Context:** Represents an external study resource (article, video, etc.) recommended to the user.
- **Information:**
  - `resourceID`: String
  - `title`: String
  - `type`: Enum (Video, Article, PDF)
  - `link`: URL
  - `tags`: List of keywords

---

### 10. `RecommendationEngine`
- **Context:** Uses subject details to suggest relevant resources.
- **Information:**
  - `fetchRecommendedResources(userID)`

---

### 11. `VoiceAssistant`
- **Context:** Enables interaction through voice commands.
- **Information:**
  - `processVoiceInput(audioData)`
  - `ProcessInput()`

---

## Prepared by

- **ID:** 202412081
- **Name:** Dev Raval 
- **Project:** AcaAssist  
- **Course:** Software Design and Testing (IT643)
- **Date:** July 26, 2025
