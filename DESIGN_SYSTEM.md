# Contest HQ Design System

**Version:** 1.0  
**Last Updated:** February 6, 2026

This document defines the design language and UI patterns for Contest HQ. It provides guidelines for maintaining visual consistency and semantic clarity across the application.

---

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Color System](#color-system)
3. [Typography](#typography)
4. [Buttons](#buttons)
5. [Forms](#forms)
6. [Cards & Containers](#cards--containers)
7. [Lists & Tables](#lists--tables)
8. [Spacing & Layout](#spacing--layout)
9. [Component Patterns](#component-patterns)
10. [Code Examples](#code-examples)

---

## Design Philosophy

Contest HQ follows these core design principles:

- **Semantic Clarity**: UI elements clearly communicate their purpose through color and style
- **Consistency**: Repeated patterns across all pages for predictable user experience
- **Accessibility**: WCAG-compliant color contrast and keyboard navigation
- **Professional**: Clean, minimal design suitable for educational organizations
- **Distinctive**: 3D button effect (4px bottom border) creates visual depth

---

## Color System

### Overview

All colors are defined as CSS custom properties in `/app/assets/tailwind/application.css`. This allows you to customize the entire color scheme by editing a single location.

### Color Variables

| Variable | Purpose | Default Value | Tailwind Equivalent |
|----------|---------|---------------|---------------------|
| `--color-primary` | Primary action buttons | `37 99 235` | blue-600 |
| `--color-primary-hover` | Primary button hover | `59 130 246` | blue-500 |
| `--color-primary-border` | Primary button border | `30 58 138` | blue-900 |
| `--color-secondary` | Secondary buttons | `243 244 246` | gray-100 |
| `--color-secondary-hover` | Secondary hover | `229 231 235` | gray-200 |
| `--color-secondary-border` | Secondary border | `156 163 175` | gray-400 |
| `--color-danger-text` | Danger button text | `153 27 27` | red-800 |
| `--color-danger-bg-hover` | Danger hover bg | `254 226 226` | red-100 |
| `--color-danger-border` | Danger border | `254 202 202` | red-200 |
| `--color-heading` | All headings | `41 37 36` | stone-800 |
| `--color-body` | Body text | `0 0 0` | black |
| `--color-muted` | Secondary text | `107 114 128` | gray-500 |
| `--color-page-bg` | Page background | `245 245 245` | neutral-100 |
| `--color-card-bg` | Card background | `255 255 255` | white |
| `--color-card-header-from` | Card header gradient start | `29 78 216` | blue-700 |
| `--color-card-header-to` | Card header gradient end | `37 99 235` | blue-600 |
| `--color-card-header-border` | Card header border | `30 58 138` | blue-900 |
| `--color-success` | Success indicators | `22 163 74` | green-600 |
| `--color-success-bg` | Success background | `240 253 244` | green-50 |
| `--color-success-text` | Success text | `21 128 61` | green-700 |

### Customizing Colors

#### Step 1: Edit CSS Variables

Open `/app/assets/tailwind/application.css` and find the `:root` section (around line 42). Modify the RGB values:

```css
:root {
  --color-primary: 22 163 74;        /* Change to green-600 */
  --color-primary-hover: 34 197 94;  /* Change to green-500 */
  /* ... update other related colors ... */
}
```

#### Step 2: Rebuild Tailwind

```bash
# If using bin/dev (development)
# Just save the file - it will auto-rebuild

# If in production
bin/rails assets:precompile
```

#### Step 3: Refresh Browser

Hard refresh your browser (Cmd+Shift+R or Ctrl+Shift+R) to see changes.

### Pre-Made Themes

The CSS file includes commented-out theme presets. To use one:

1. Open `/app/assets/tailwind/application.css`
2. Find the "Alternative Color Themes" section (around line 90)
3. Uncomment ONE theme block
4. Rebuild Tailwind

Available themes:
- **Forest Green** - Professional green for environmental organizations
- **Royal Purple** - Elegant purple for arts organizations
- **Crimson Red** - Bold red for high-energy organizations
- **Teal** - Modern teal for tech-forward organizations
- **Amber/Gold** - Warm amber for traditional organizations

### RGB Format

Colors use space-separated RGB values (e.g., `37 99 235`) to work with Tailwind's opacity modifiers:

```css
/* Solid color */
background-color: rgb(var(--color-primary));

/* With opacity */
background-color: rgb(var(--color-primary) / 0.5); /* 50% opacity */
```

### Finding RGB Values

- **Tailwind Colors**: https://tailwindcss.com/docs/customizing-colors
- **Hex to RGB Converter**: https://www.rapidtables.com/convert/color/hex-to-rgb.html
- **Browser DevTools**: Use the color picker in Chrome/Firefox DevTools

---

## Typography

### Font Family

**Inter** - Variable font (weights 100-900)  
Loaded from Google Fonts, applied to all elements via `--font-inter` variable.

### Heading Styles

All headings use `--color-heading` (default: stone-800).

| Element | Size | Weight | Usage |
|---------|------|--------|-------|
| `h1` | 4xl (2.25rem) | Bold | Page titles |
| `h2` | 3xl (1.875rem) | Bold | Section headers |
| `h3` | Base (1rem) | Semibold | Subsection headers |

### Text Patterns

```erb
<!-- Page title -->
<h1>Contest Management</h1>

<!-- Section header -->
<h2>Active Contests</h2>

<!-- Subsection header -->
<h3>Performance Details</h3>

<!-- Body text (default styling) -->
<p>Regular paragraph text</p>

<!-- Metadata/secondary text -->
<p class="text-sm text-gray-500">Created on Jan 15, 2026</p>

<!-- Muted text -->
<span class="text-xs text-gray-500">Optional field</span>
```

---

## Buttons

### Semantic Button Usage

Buttons follow strict semantic rules based on their action:

| Class | Purpose | Examples | Color |
|-------|---------|----------|-------|
| `btn-primary-sm` | **State-changing actions** | Save, Submit, Create, Update, Edit, Confirm, Add | Blue |
| `btn-secondary-sm` | **Non-state-changing actions** | Cancel, Back, Close, View, Return | Gray |
| `btn-danger-sm` | **Destructive actions** | Delete, Destroy, Remove, Archive | Red |

### Button Size Standard

**Small buttons (`-sm`) are the default** across the application for consistency and professional appearance.

**Large buttons** (without `-sm` suffix) are reserved for special emphasis:
- Landing page CTAs (e.g., "Request Beta Access")
- Authentication forms (Sign In, Sign Up)
- Empty state primary actions (e.g., "New Contest", "Create Entry")

**Why small buttons?**
- More compact and professional appearance
- Better use of screen space
- Consistent visual weight across the application
- Already used in the best-designed pages

### Visual Design

All buttons feature:
- **3D Effect**: 4px bottom border creates raised appearance
- **Rounded Corners**: `rounded-lg` (8px radius)
- **Responsive Width**: Full width on mobile, auto width on desktop
- **Smooth Transitions**: Hover states animate smoothly

### Button Positioning

**Forms**: Right-aligned on desktop, stacked on mobile
```erb
<div class="form-button-container">
  <%= form.submit "Save", class: "btn-primary" %>
  <%= link_to "Cancel", contests_path, class: "btn-secondary" %>
</div>
```

**Action Containers**: Right-aligned, flexible spacing
```erb
<div class="action-button-container">
  <%= link_to "Edit", edit_contest_path(@contest), class: "btn-primary-sm" %>
  <%= link_to "Back", contests_path, class: "btn-secondary-sm" %>
</div>
```

### Button Examples

```erb
<!-- Primary: Save form -->
<%= form.submit "Save School", class: "btn-primary-sm" %>

<!-- Primary: Edit (state-changing) -->
<%= link_to "Edit", edit_contest_path(@contest), class: "btn-primary-sm" %>

<!-- Primary: Create new -->
<%= link_to "Add Manager", new_manager_path, class: "btn-primary-sm" %>

<!-- Secondary: Cancel -->
<%= link_to "Cancel", schools_path, class: "btn-secondary-sm" %>

<!-- Secondary: Back navigation -->
<%= link_to "Back to List", contests_path, class: "btn-secondary-sm" %>

<!-- Danger: Delete -->
<%= button_to "Delete", school_path(@school), method: :delete, 
    class: "btn-danger-sm", 
    data: { turbo_confirm: "Are you sure?" } %>

<!-- Large buttons (special cases only) -->
<%= link_to "Request Beta Access", "#signup", class: "btn-primary" %> <!-- Landing page CTA -->
<%= form.submit "Sign In", class: "btn-primary" %> <!-- Auth form -->
<%= link_to "New Contest", new_contest_path, class: "btn-primary" %> <!-- Empty state -->
```

### Common Mistakes to Avoid

❌ **Wrong**: Using `btn-primary-sm` for Cancel
```erb
<%= link_to "Cancel", contests_path, class: "btn-primary-sm" %>
```

✅ **Correct**: Using `btn-secondary-sm` for Cancel
```erb
<%= link_to "Cancel", contests_path, class: "btn-secondary-sm" %>
```

❌ **Wrong**: Using `btn-secondary-sm` for Save or Edit
```erb
<%= form.submit "Save", class: "btn-secondary-sm" %>
<%= link_to "Edit", edit_path(@resource), class: "btn-secondary-sm" %>
```

✅ **Correct**: Using `btn-primary-sm` for Save and Edit
```erb
<%= form.submit "Save", class: "btn-primary-sm" %>
<%= link_to "Edit", edit_path(@resource), class: "btn-primary-sm" %>
```

❌ **Wrong**: Using large buttons in forms or show pages
```erb
<%= form.submit "Save", class: "btn-primary" %>
<%= link_to "Edit", edit_path(@resource), class: "btn-primary" %>
```

✅ **Correct**: Using small buttons everywhere except special cases
```erb
<%= form.submit "Save", class: "btn-primary-sm" %>
<%= link_to "Edit", edit_path(@resource), class: "btn-primary-sm" %>
```

---

## Forms

### Form Layouts

Two standard layouts based on form complexity:

#### Simple Form (`simple-form`)

**Use for**: Login, registration, password reset, simple settings

**Characteristics**:
- Single column layout
- Max width: `max-w-md` (28rem / 448px)
- Centered on page
- Vertical spacing: 1rem gap

**Container**: `simple-form-container`

```erb
<div class="simple-form-container">
  <%= form_with model: @user, class: "simple-form" do |form| %>
    <%= form.label :email, style: "display: block" %>
    <%= form.email_field :email, class: "text-field" %>
    
    <%= form.label :password, style: "display: block" %>
    <%= form.password_field :password, class: "text-field" %>
    
    <div class="form-button-container">
      <%= form.submit "Sign In", class: "btn-primary" %>
    </div>
  <% end %>
</div>
```

#### Wide Form (`wide-form`)

**Use for**: CRUD forms (schools, contests, users, ensembles)

**Characteristics**:
- Two-column grid on desktop, single column on mobile
- Max width: `max-w-4xl` (56rem / 896px)
- Centered on page
- Grid gap: 1rem

**Container**: `wide-form-container`

**Full-width fields**: Use `sm:col-span-2` to span both columns

```erb
<div class="wide-form-container">
  <%= form_with model: @school, class: "wide-form" do |form| %>
    <div>
      <%= form.label :name, style: "display: block" %>
      <%= form.text_field :name, class: "text-field" %>
    </div>
    
    <div>
      <%= form.label :code, style: "display: block" %>
      <%= form.text_field :code, class: "text-field" %>
    </div>
    
    <div class="sm:col-span-2">
      <%= form.label :address, style: "display: block" %>
      <%= form.text_field :address, class: "text-field" %>
    </div>
    
    <div class="form-button-container">
      <%= form.submit "Save School", class: "btn-primary" %>
      <%= link_to "Cancel", schools_path, class: "btn-secondary" %>
    </div>
  <% end %>
</div>
```

### Shared Form Wrapper

**New in v1.0**: Use `shared/form_wrapper` partial for consistent form layout.

See [Shared Form Wrapper](#shared-form-wrapper-partial) section below.

### Form Fields

#### Text Input

```erb
<%= form.label :name, style: "display: block" %>
<%= form.text_field :name, class: "text-field" %>
```

#### Select Dropdown

```erb
<%= form.label :status, style: "display: block" %>
<%= form.select :status, 
    [["Active", "active"], ["Archived", "archived"]], 
    {}, 
    class: "text-field" %>
```

#### Textarea

```erb
<%= form.label :description, style: "display: block" %>
<%= form.text_area :description, rows: 4, class: "text-field" %>
```

#### Checkbox

```erb
<%= form.label :active do %>
  <%= form.check_box :active %>
  <span class="ml-2">Active</span>
<% end %>
```

#### Checkbox Group

```erb
<div class="sm:col-span-2">
  <%= form.label :role_ids, "Roles", style: "display: block" %>
  <div class="flex flex-col space-y-2 border border-gray-400 bg-white shadow p-4 rounded-md">
    <%= form.collection_checkboxes :role_ids, @roles, :id, :name do |helper| %>
      <%= helper.label do %>
        <%= helper.check_box %><span class="ml-2"><%= helper.text %></span>
      <% end %>
    <% end %>
  </div>
</div>
```

### Error Messages

Use the `layouts/error_messages` partial:

```erb
<% if @school.errors.any? %>
  <%= render "layouts/error_messages", errors: @school.errors %>
<% end %>
```

---

## Cards & Containers

### Card Component

Cards are the primary container for grouped content.

**Structure**:
```erb
<div class="card">
  <div class="card-header">
    Section Title
  </div>
  <div class="px-4 py-5 sm:p-6">
    <!-- Card content -->
  </div>
</div>
```

**Visual Design**:
- White background with neutral border
- Rounded corners (`rounded-lg`)
- Divided sections with gray dividers
- Blue gradient header with 4px bottom border

**Example** (`app/views/home/dashboards/_director.html.erb:22-60`):
```erb
<div class="card">
  <div class="card-header">
    Active Contests
  </div>
  <div class="px-4 py-5 sm:p-6">
    <%= render "contests/list", contests: @active_contests %>
  </div>
</div>
```

### Page Container

Standard page wrapper with max-width and centered:

```erb
<div class="container p-6">
  <!-- Page content -->
</div>
```

**Utility**: `container` = `mx-auto max-w-4xl`

---

## Lists & Tables

### List Pattern (Primary)

**Use for**: Most list views (contests, schools, users)

**File**: `app/views/contests/_list.html.erb`

```erb
<ul role="list" class="px-4 divide-y divide-gray-100">
  <% contests.each do |contest| %>
    <li class="flex items-center justify-between gap-x-6 py-5">
      <div class="min-w-0">
        <div class="flex items-start gap-x-3">
          <p class="font-semibold text-gray-900"><%= contest.name %></p>
        </div>
        <div class="mt-1 gap-x-2 text-xs/5 text-gray-500">
          <%= contest.season.name %> • <%= contest.start_date.strftime("%B %d, %Y") %>
        </div>
      </div>
      <div class="flex flex-none items-center gap-x-4">
        <%= link_to "View", contest_path(contest), class: "btn-primary-sm" %>
      </div>
    </li>
  <% end %>
</ul>
```

**Key Features**:
- Divided list with gray-100 dividers
- Flexbox layout for responsive design
- Bold item name, gray metadata
- Right-aligned action buttons
- 5-unit vertical padding per item

### Table Pattern (Secondary)

**Use for**: Admin interfaces, management views

**File**: `app/views/contests/rooms/_room_list.html.erb`

```erb
<table class="min-w-full divide-y divide-gray-300 table-auto">
  <thead>
    <tr>
      <th class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6">
        Name
      </th>
      <th scope="col" class="flex justify-end p-2">
        <%= link_to "Add Room", new_contest_room_path(@contest), 
            class: "btn-primary-sm" %>
      </th>
    </tr>
  </thead>
  <tbody class="divide-y divide-gray-200 bg-white">
    <% @rooms.each do |room| %>
      <tr>
        <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-6">
          <%= room.name %>
        </td>
        <td class="flex justify-end space-x-2 p-2">
          <%= link_to "Edit", edit_contest_room_path(@contest, room), 
              class: "btn-primary-sm" %>
          <%= button_to "Delete", contest_room_path(@contest, room), 
              method: :delete, class: "btn-danger-sm" %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>
```

### Empty State

```erb
<div class="text-center pb-4">
  <svg class="mx-auto size-12 text-gray-400" fill="none" viewBox="0 0 24 24" 
       stroke="currentColor" aria-hidden="true">
    <path vector-effect="non-scaling-stroke" stroke-linecap="round" 
          stroke-linejoin="round" stroke-width="2" 
          d="M9 13h6m-3-3v6m-9 1V7a2 2 0 012-2h6l2 2h6a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2z" />
  </svg>
  <h3 class="mt-2 text-sm font-semibold text-gray-900">No contests</h3>
  <p class="mt-1 text-sm text-gray-500">Get started by creating a new contest.</p>
  <div class="mt-6">
    <%= link_to "Create Contest", new_contest_path, class: "btn-primary" %>
  </div>
</div>
```

---

## Spacing & Layout

### Container Widths

| Utility | Max Width | Usage |
|---------|-----------|-------|
| `container` | 56rem (896px) | Page content |
| `simple-form-container` | 28rem (448px) | Simple forms |
| `wide-form-container` | 56rem (896px) | CRUD forms |

### Common Spacing Patterns

| Pattern | Utility | Usage |
|---------|---------|-------|
| Page padding | `p-6` | Main content wrapper |
| Section spacing | `space-y-4` | Vertical stack of elements |
| Card padding | `px-4 py-5 sm:p-6` | Card content area |
| Button spacing | `space-x-2` or `gap-2` | Horizontal button groups |
| List item padding | `py-5` | List items |
| Form field spacing | `gap-4` | Form grid gaps |

### Responsive Breakpoints

Tailwind's default breakpoints:
- `sm:` - 640px and up
- `md:` - 768px and up
- `lg:` - 1024px and up
- `xl:` - 1280px and up

Common responsive patterns:
```erb
<!-- Full width mobile, auto width desktop -->
<button class="w-full sm:w-auto">Button</button>

<!-- Single column mobile, two columns desktop -->
<div class="grid grid-cols-1 md:grid-cols-2 gap-4">

<!-- Stacked mobile, horizontal desktop -->
<div class="flex flex-col sm:flex-row sm:space-x-2">
```

---

## Component Patterns

### Entity Detail Wrapper

**File**: `app/views/shared/_entity_detail.html.erb`

**Standard pattern for all show pages.** Wraps show pages with consistent header and action buttons at the top.

```erb
<%= render "shared/entity_detail", 
    entity: @contest, 
    title: @contest.name,
    entity_partial: "contests/contest",
    actions: (capture do %>
      <%= link_to "Edit", edit_contest_path(@contest), class: "btn-primary-sm" %>
      <%= button_to "Delete", @contest, method: :delete, class: "btn-danger-sm",
          form: { data: { turbo_confirm: "Are you sure?" } } %>
    <% end) do %>
  <!-- Page content goes here -->
<% end %>
```

**Key Features:**
- Edit/Delete buttons appear at top-right (desktop) or top (mobile)
- Uses `action-button-container` for proper alignment
- Consistent across all show pages
- Clean separation of actions from content

### Breadcrumbs

**File**: `app/views/shared/_breadcrumbs.html.erb`

```erb
<%= render "shared/breadcrumbs", breadcrumbs: [
  OpenStruct.new(name: "Contests", path: contests_path),
  OpenStruct.new(name: @contest.name, path: contest_path(@contest))
] %>
```

### Notification

**File**: `app/views/shared/_notification.html.erb`

Auto-dismissing notification for flash messages:

```erb
<% if notice %>
  <%= render "shared/notification", message: notice, type: "notice" %>
<% end %>
```

### Status Badges

**Active Status**:
```erb
<span class="inline-flex items-center rounded-md bg-green-50 px-2 py-1 
             text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20">
  Active
</span>
```

**Archived Status**:
```erb
<span class="inline-flex items-center rounded-md bg-gray-50 px-2 py-1 
             text-xs font-medium text-gray-600 ring-1 ring-inset ring-gray-500/10">
  Archived
</span>
```

### Modals

**Backdrop**:
```erb
<div class="modal-backdrop bg-gray-500 opacity-75"></div>
```

**Small Modal**:
```erb
<div class="modal-small">
  <!-- Modal content -->
</div>
```

**Full Screen Modal**:
```erb
<div class="modal-full-screen">
  <!-- Modal content -->
</div>
```

---

## Code Examples

### Complete CRUD Form Example

```erb
<%# app/views/schools/_form.html.erb %>

<div class="wide-form-container">
  <%= form_with model: @school, class: "wide-form" do |form| %>
    <% if @school.errors.any? %>
      <%= render "layouts/error_messages", errors: @school.errors %>
    <% end %>
    
    <div>
      <%= form.label :name, style: "display: block" %>
      <%= form.text_field :name, class: "text-field" %>
    </div>
    
    <div>
      <%= form.label :code, style: "display: block" %>
      <%= form.text_field :code, class: "text-field" %>
    </div>
    
    <div class="sm:col-span-2">
      <%= form.label :address, style: "display: block" %>
      <%= form.text_field :address, class: "text-field" %>
    </div>
    
    <div>
      <%= form.label :city, style: "display: block" %>
      <%= form.text_field :city, class: "text-field" %>
    </div>
    
    <div>
      <%= form.label :state, style: "display: block" %>
      <%= form.text_field :state, class: "text-field" %>
    </div>
    
    <div class="form-button-container">
      <%= form.submit "Save School", class: "btn-primary" %>
      <%= link_to "Cancel", schools_path, class: "btn-secondary" %>
    </div>
  <% end %>
</div>
```

### Complete List View Example

```erb
<%# app/views/schools/index.html.erb %>

<div class="py-8">
  <div class="flex flex-col sm:flex-row">
    <h1>Schools</h1>
    <div class="action-button-container">
      <%= link_to "Add School", new_school_path, class: "btn-primary" %>
    </div>
  </div>
  
  <div class="card mt-6">
    <div class="card-header">
      All Schools
    </div>
    <% if @schools.any? %>
      <ul role="list" class="px-4 divide-y divide-gray-100">
        <% @schools.each do |school| %>
          <li class="flex items-center justify-between gap-x-6 py-5">
            <div class="min-w-0">
              <div class="flex items-start gap-x-3">
                <p class="font-semibold text-gray-900"><%= school.name %></p>
              </div>
              <div class="mt-1 gap-x-2 text-xs/5 text-gray-500">
                <%= school.city %>, <%= school.state %>
              </div>
            </div>
            <div class="flex flex-none items-center gap-x-4">
              <%= link_to "View", school_path(school), class: "btn-primary-sm" %>
            </div>
          </li>
        <% end %>
      </ul>
    <% else %>
      <div class="text-center py-12">
        <h3 class="mt-2 text-sm font-semibold text-gray-900">No schools</h3>
        <p class="mt-1 text-sm text-gray-500">Get started by adding a school.</p>
        <div class="mt-6">
          <%= link_to "Add School", new_school_path, class: "btn-primary" %>
        </div>
      </div>
    <% end %>
  </div>
</div>
```

### Complete Show Page Example

```erb
<%# app/views/schools/show.html.erb %>

<%= render "shared/entity_detail", 
    entity: @school, 
    title: @school.name,
    actions: capture do %>
  <%= link_to "Edit", edit_school_path(@school), class: "btn-primary-sm" %>
  <%= button_to "Delete", school_path(@school), method: :delete, 
      class: "btn-danger-sm", 
      data: { turbo_confirm: "Are you sure?" } %>
  <%= link_to "Back", schools_path, class: "btn-secondary-sm" %>
<% end %> do %>
  
  <div class="card mt-6">
    <div class="card-header">
      School Details
    </div>
    <div class="px-4 py-5 sm:p-6">
      <dl class="grid grid-cols-1 gap-x-4 gap-y-6 sm:grid-cols-2">
        <div>
          <dt class="text-sm font-medium text-gray-500">Name</dt>
          <dd class="mt-1 text-sm text-gray-900"><%= @school.name %></dd>
        </div>
        
        <div>
          <dt class="text-sm font-medium text-gray-500">Code</dt>
          <dd class="mt-1 text-sm text-gray-900"><%= @school.code %></dd>
        </div>
        
        <div class="sm:col-span-2">
          <dt class="text-sm font-medium text-gray-500">Address</dt>
          <dd class="mt-1 text-sm text-gray-900">
            <%= @school.address %><br>
            <%= @school.city %>, <%= @school.state %>
          </dd>
        </div>
      </dl>
    </div>
  </div>
<% end %>
```

### Shared Form Wrapper Partial

**New in v1.0**: Standardized form wrapper with automatic layout and buttons.

**File**: `app/views/shared/_form_wrapper.html.erb`

**Usage**:
```erb
<%= form_with model: @school, class: "wide-form" do |form| %>
  <%= render "shared/form_wrapper",
      form: form,
      submit_text: "Save School",
      cancel_path: schools_path,
      entity: @school do %>
    
    <div>
      <%= form.label :name, style: "display: block" %>
      <%= form.text_field :name, class: "text-field" %>
    </div>
    
    <div>
      <%= form.label :code, style: "display: block" %>
      <%= form.text_field :code, class: "text-field" %>
    </div>
  <% end %>
<% end %>
```

**Parameters**:
- `form` (required) - FormBuilder instance
- `submit_text` (optional) - Submit button text (default: "Save")
- `cancel_path` (required) - Path for cancel button
- `show_cancel` (optional) - Show cancel button (default: `true`)
- `entity` (optional) - Model instance for error display

**Benefits**:
- Automatic error message display
- Consistent button positioning (right-aligned on desktop)
- Proper button semantics (primary for submit, secondary for cancel)
- Reduces code duplication across forms

---

## Quick Reference

### When to Use What

| Scenario | Component | File Reference |
|----------|-----------|----------------|
| Save/Submit action | `btn-primary` | `application.css:96` |
| Cancel/Back action | `btn-secondary` | `application.css:109` |
| Delete action | `btn-danger` | `application.css:122` |
| Login form | `simple-form` | `sessions/new.html.erb` |
| CRUD form | `wide-form` | `schools/_form.html.erb` |
| List of items | List pattern | `contests/_list.html.erb` |
| Admin table | Table pattern | `rooms/_room_list.html.erb` |
| Grouped content | Card | `home/dashboards/_director.html.erb` |
| Show page | Entity detail | `contests/show.html.erb` |

### Common File Locations

| Component | File Path |
|-----------|-----------|
| CSS Variables | `app/assets/tailwind/application.css:42` |
| Button Utilities | `app/assets/tailwind/application.css:96` |
| Form Utilities | `app/assets/tailwind/application.css:157` |
| Card Utilities | `app/assets/tailwind/application.css:289` |
| Typography | `app/assets/tailwind/application.css:297` |
| Entity Detail | `app/views/shared/_entity_detail.html.erb` |
| Error Messages | `app/views/layouts/_error_messages.html.erb` |
| Notification | `app/views/shared/_notification.html.erb` |
| Breadcrumbs | `app/views/shared/_breadcrumbs.html.erb` |

---

## Support & Feedback

For questions or suggestions about the design system:

1. Check this documentation first
2. Review existing code examples in the codebase
3. Consult with the development team
4. Propose changes via pull request

**Last Updated**: February 6, 2026  
**Version**: 1.0
