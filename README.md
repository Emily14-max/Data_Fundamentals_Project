# 🎵 Music App 🔐 Admin Roles & Security Database - Data Fundamentals Project

## 📗 Table of Contents

- [📖 About the Project](#about-project)
  - [🛠 Built With](#built-with)
    - [Tech Stack](#tech-stack)
    - [Key Features](#key-features)
  - [🚀 Live Demo](#live-demo)
- [💻 Getting Started](#getting-started)
  - [Setup](#setup)
  - [Prerequisites](#prerequisites)
  - [Install](#install)
  - [Usage](#usage)
  - [Run tests](#run-tests)
- [🔒 Security Implementation](#security-implementation)
- [🔒 Security Policies](#security-policies)
- [👥 Roles Implementation](#roles-implementation)
- [👥 Authors](#authors)
- [🔭 Future Features](#future-features)
- [🤝 Contributing](#contributing)
- [⭐️ Show your support](#support)
- [🙏 Acknowledgements](#acknowledgements)
- [❓ FAQ](#faq)

<!-- PROJECT DESCRIPTION -->

# 📖 Admin Roles & Security Database <a name="about-project"></a>

> A secure PostgreSQL database for a music streaming platform implementing role-based access control and Row Level Security in Supabase.

This project builds upon the existing  Music Streaming Database to implement advanced security features including user roles, admin privileges, and database-level security policies for a modern web application.

## 🛠 Built With <a name="built-with"></a>

### Tech Stack <a name="tech-stack"></a>

> Security-focused tech stack for database access control.

<details>
  <summary>Database</summary>
  <ul>
    <li><a href="https://www.postgresql.org/">PostgreSQL</a></li>
  </ul>
</details>

<details>
  <summary>Security</summary>
  <ul>
    <li><a href="https://www.postgresql.org/docs/current/ddl-rowsecurity.html">Row Level Security (RLS)</a></li>
    <li><a href="https://supabase.com/auth">Supabase Auth</a></li>
  </ul>
</details>

<details>
<summary>Platform</summary>
  <ul>
    <li><a href="https://supabase.com/">Supabase</a></li>
  </ul>
</details>

<!-- Features -->

### Key Features <a name="key-features"></a>

> Core security features implemented in this project.

- **Role-Based Access Control** - Admin and User roles with different permissions
- **Row Level Security** - Data access restrictions at the database level
- **Admin Privileges** - Secure admin-only functions and operations
- **Authentication Integration** - Supabase Auth with role management

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- LIVE DEMO -->

## 🚀 Live Demo <a name="live-demo"></a>

> This security implementation is built on top of the existing Music Streaming Database.

- Security Policies: Available in `security_policies.sql`
- Admin Functions: See `admin_functions.sql`
- Documentation: Complete setup instructions in `security_notes.md`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

## 💻 Getting Started <a name="getting-started"></a>

> Follow these steps to implement security features in your Supabase project.

### Prerequisites
In order to run this project you need:
- A Supabase account (free tier available)
- Existing Supabase project with database tables
- Basic SQL and database security knowledge
- Understanding of role-based access control concepts

### Setup
1. Ensure you have the Music Streaming Database setup in Supabase
2. Clone this repository:

```bash
git clone https://github.com/Emily14-max/data-fundamentals-project.git
cd data-fundamentals-project
```

### Install

> Install this project with:

1. Open your Supabase project SQL Editor
2. Execute the security setup scripts
3. Enable authentication in your Supabase project settings

### Usage

**For Regular Users**:
- Sign up through Supabase Auth
- Your user record will be created with role = 'user'
- You can view, create, update, and delete your own projects and tasks
- You cannot access other users' data

**For Administrators**:
- Users with role = 'admin' in the users table have full access
- Can view and manage all users, projects, and tasks

> To implement security policies, use the Supabase SQL editor:

```sql
-- Enable Row Level Security on all tables
ALTER TABLE music.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE music.artists ENABLE ROW LEVEL SECURITY;
ALTER TABLE music.songs ENABLE ROW LEVEL SECURITY;

-- Create admin full-access policy
CREATE POLICY "Admins have full access to users" ON music.users
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM music.users 
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

-- Create user restricted policy
CREATE POLICY "Users can view own profile" ON music.users
FOR SELECT USING (auth.uid() = user_id);
```

### Run tests
> To run security tests, run the following commands:

```sql
-- Test RLS policies
-- Regular user should only see their own data
SELECT * FROM music.users;

-- Admin should see all data
SELECT * FROM music.users WHERE role = 'admin';

-- Test admin functions
SELECT music.get_current_user_role();
SELECT music.get_user_statistics();

-- Verify policy enforcement
SELECT schemaname, tablename, policyname, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'music';
```
<p align="right">(<a href="#readme-top">back to top</a>)</p>

# 🔒 Security Implementation <a name="security-implementation"></a>

### Security Architecture
> The security implementation follows a layered approach with Row Level Security at the database level, role-based access control at the application level and secure functions for administrative operations.

### Security Components
- **RLS Policies**: security policies implementing least privilege principle

- **Admin Functions**:  secure functions for administrative operations

- **Role Management**: Admin and User roles with granular permissions

- **Authentication**: Integrated with Supabase Auth system

 ### Security Functions

- `get_current_user_role()` - Returns current user's role

- `delete_user()` - Admin-only user deletion

- `update_user_role()` - Admin-only role management

- `get_user_statistics()` - Admin-only analytics

 <p align="right">(<a href="#readme-top">back to top</a>)</p>

# 🔒 Security Policies <a name="security-policies"></a>

## Row Level Security (RLS) Overview

> Row Level Security is enabled on all three tables to enforce data access restrictions at the database level. This ensures security even if application-level checks are bypassed.

## Policy Implementation Details

### Users Table Policies

1. **Admin Full Access Policy**

- **Scope**: ALL operations (SELECT, INSERT, UPDATE, DELETE)

- **Access**: Complete access to all user records

- **Use Case**: System administrators managing user accounts

2. **User Self-View Policy**

- **Scope**: SELECT operations only

- **Access**: Users can only see their own record

- **Use Case**: Users viewing their profile page

3. **User Self-Update Policy**

- **Scope**: UPDATE operations only

- **Access**: Users can modify their own data

- **Use Case**: Users updating personal information

### Artists Table Policies

4. **Admin Full Access to Artists**

- **Scope**: ALL operations

- **Access**: Complete artist catalog management

- **Use Case**: Adding new artists, updating information

5. **User Read-Only Access to Artists**
 
- **Scope**: SELECT operations only

- **Access**: All users can browse artists

- **Use Case**: Music discovery and browsing

### Songs Table Policies

6. **Admin Full Access to Songs**

- **Scope**: ALL operations

- **Access**: Complete song catalog management

- **Use Case**: Adding new songs, updating metadata

7. **User Read-Only Access to Songs**

- **Scope**: SELECT operations only

- **Access**: All users can browse songs

- **Use Case**: Music streaming and discovery

<p align="right">(<a href="#readme-top">back to top</a>)</p>

# 👥 Roles Implementation <a name="roles-implementation"></a>

## Role-Based Access Control System 

>This project implements a comprehensive role-based access control (RBAC) system with two primary roles:

### 🛡️ Admin Role

**Purpose**: Full system administration with complete database access

**Permissions**:

✅ **Full CRUD** - Access on all tables (users, artists, songs)

✅ **User Management** - Create, read, update, delete any user

✅ **Role Assignment** - Promote/demote users between roles

✅ **System Analytics** - Access to statistical functions

✅ **Data Maintenance** - Bulk operations and cleanup

### 👤 User Role

**Purpose**: Regular platform users with restricted access

**Permissions**:

✅ **Read Own Profile** - View personal user information

✅ **Update Own Data** - Modify personal details

✅ **Browse Catalog** - Read-only access to artists and songs

❌ **No User Management** - Cannot access other users' data

❌ **No Administrative Functions** - Limited to basic operations

### Access Control Matrix

|Table	|Admin Access|	User Access|
|-------|------------|-------------|
|users	|Full CRUD|	Read/Update own data|
|artists| Full CRUD|	Read-only|
|songs	|Full CRUD	|Read-only|

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- AUTHORS -->

## 👥 Authors <a name="authors"></a>

> Data Fundamentals Project - Security Implementation

👤 **Project Developer**

- GitHub: [@Emily14-max](https://github.com/Emily14-max)
- Project: [admin-security-supabase](https://github.com/Emily14-max/music_app_admin_security_database)


<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- FUTURE FEATURES -->

## 🔭 Future Features <a name="future-features"></a>

> Planned security enhancements for the system.

- [ ] **Advanced audit logging and monitoring**

- [ ] **Two-factor authentication integration**

- [ ] **Automated security compliance reporting**

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTRIBUTING -->

## 🤝 Contributing <a name="contributing"></a>

Contributions, issues and feature requests are welcome!

Feel free to check the [issues page](https://github.com/Emily14-max/data_fundamental_project/issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- SUPPORT -->

## ⭐️ Show your support <a name="support"></a>

> Support this database security implementation project!

If you like this project, please give it a star on GitHub and share it with developers interested in database security and access control. This project demonstrates:

- Proper Row Level Security implementation

- Role-based access control patterns

- Secure database function design

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGEMENTS -->

## 🙏 Acknowledgments <a name="acknowledgements"></a>

> Credits and inspiration for this security project.

I would like to thank:

- **Supabase** for excellent PostgreSQL security documentation

- **PostgreSQL Community** for robust Row Level Security features

- **Data Fundamentals Course instructors** for project guidance

- **Open Source Security Tools** that inspired best practices

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- FAQ (optional) -->

## ❓ FAQ (OPTIONAL) <a name="faq"></a>

> Common questions about the security implementation.

- **What is Row Level Security and why is it important?**

  - Row Level Security (RLS) is a PostgreSQL feature that restricts which rows users can access in database tables. It's important because it provides data security at the database level,ensuring users can only access data they're authorized to see.

- **Can I use this security setup in production environments?**

   - This project demonstrates security concepts that are production-ready. However, for production use, you should conduct thorough security testing, implement additional monitoring and follow your organization's security policies.

<p align="right">(<a href="#readme-top">back to top</a>)</p>
