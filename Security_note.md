# 🔒 Security Setup Notes - Music App Database

## Overview
This document outlines the security implementation for the Music Streaming Database using Supabase PostgreSQL with Row Level Security (RLS) and role-based access control.

## Security Principles Implemented

### 1. Principle of Least Privilege
- Users receive only the permissions necessary to perform their tasks
- Regular users can only access their own data
- Administrative functions are restricted to admin role only

### 2. Defense in Depth
- Multiple security layers: Authentication → RLS → Application Logic
- Each layer provides independent security validation

### 3. Secure Defaults
- RLS enabled on all tables by default
- Explicit policies required for any data access
- Default deny all, then allow specific operations

## Security Architecture

### Authentication Layer
```sql
-- Supabase Auth handles user authentication
-- Users sign up with email/password or magic links
-- Each user gets a unique auth.uid() for data isolation
```

### Setup Requirements
1. Enable **Supabase Auth** in your project
2. Configure authentication provider (email/password or magic link)
3. Ensure `auth.uid()` is properly populated on authentication
4. Map authenticated users to the `users` table

### Authentication Flow
1. User signs up/signs in through Supabase Auth
2. Supabase generates a JWT token with user ID
3. User ID becomes available as `auth.uid()` in database queries
4. RLS policies use `auth.uid()` to enforce access control

### Authorization Layer

#### Role Definitions:
- **Admin Role**: Full database access (CREATE, READ, UPDATE, DELETE)
- **User Role**: Limited access (READ own data, INSERT new owned data)

## Row Level Security (RLS) Implementation

### What is RLS?
Row Level Security is a PostgreSQL feature that allows you to control which rows users can access in a table. When RLS is enabled on a table, all queries are filtered through policies that determine access.

### RLS Status

RLS is **enabled** on all three tables:
- ✅ `users` table
- ✅ `artists` table  
- ✅ `songs` table

## How It Works
- When a user queries a table, PostgreSQL checks all applicable policies
- If ANY policy returns `TRUE`, the user can access that row
- If ALL policies return `FALSE` or no policies match, access is denied
- Different policies can apply for different operations (SELECT, INSERT, UPDATE, DELETE)


#### Row Level Security Policies:
```sql
-- Example: Users can only view their own songs
CREATE POLICY "Users can view own songs" ON music.songs
FOR SELECT USING (auth.uid() = user_id);

-- Example: Admins have full access
CREATE POLICY "Admins full access" ON music.songs
FOR ALL USING (
  EXISTS (SELECT 1 FROM music.users WHERE id = auth.uid() AND role = 'admin')
);
```

### Data Access Layer
- All database queries pass through RLS policies
- Policies enforce data ownership and role permissions
- Custom functions provide secure administrative operations

## Implementation Details

### Table Security Setup
1. **Enable RLS on all tables**
2. **Create policies for each operation** (SELECT, INSERT, UPDATE, DELETE)
3. **Test policies with different user roles**

### User Management

- User role assignment during registration
- Admin users must be explicitly promoted
- Regular users have restricted access by default

### Secure Functions

- Admin-only functions use SECURITY DEFINER
- Functions execute with elevated privileges when authorized
- Input validation prevents SQL injection

## Security Policies by Table

### users Table
- **Users**: Read/update own record only
- **Admins**: Full CRUD access to all user records

### artists Table  
- **Users**: Read access to all artists
- **Admins**: Full CRUD access to artists

### songs Table
- **Users**: Read all songs, CRUD only own songs
- **Admins**: Full CRUD access to all songs

 ## Least Privilege Principle

Our implementation follows the **principle of least privilege**:

-  **Default Deny**: With RLS enabled, users have NO access by default
-  **Explicit Grants**: Access is explicitly granted through policies
-  **Role Separation**: Clear distinction between admin and user capabilities
-  **Ownership-Based Access**: Regular users can only access their own data
-  **Immutable Roles**: Users cannot self-promote to admin status

## Testing Security Implementation

### Verification Steps:
- ✅ RLS enabled on all tables
- ✅ Policies created for each role and operation
- ✅ Users cannot access other users' data
- ✅ Admins can access all data
- ✅ Custom functions respect role permissions
- ✅ Authentication required for all operations

### Test Queries:
```sql
-- Verify RLS status
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'music';

-- Test user isolation
-- Logged in as user A should not see user B's data
```

## Security Best Practices Followed

### 1. Data Protection
- RLS prevents horizontal privilege escalation
- Auth integration ensures proper user identification
- No sensitive data exposure between users

### 2. Access Control
- Role-based permissions minimize attack surface
- Policy conditions are explicit and testable
- Regular security audits of policies

### 3. Maintenance
- Policies documented and version controlled
- Regular review of user roles and permissions
- Security testing as part of development workflow

## Incident Response

### Security Events:
1. **Policy Violation Attempt**: Log and block unauthorized access
2. **Role Compromise**: Immediately revoke and reassign roles
3. **Data Breach**: Audit logs and rollback changes

### Monitoring:
- Supabase logs track all authentication events
- Database logs record policy violations
- Regular security reviews of access patterns

## Conclusion
This security setup provides a robust foundation for the Music App Database, ensuring data privacy, access control and compliance with security best practices while maintaining usability for legitimate users.

