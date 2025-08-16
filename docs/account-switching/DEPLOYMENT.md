# Account Switching Feature Deployment Notes

## Deployment Checklist

### Pre-deployment
- [ ] Review the account switching implementation
- [ ] Ensure all tests pass
- [ ] Verify that existing AccountScoped behavior is preserved for regular users

### During Deployment
- [ ] Deploy the code changes
- [ ] No database migrations required
- [ ] No special configuration changes needed

### Post-deployment
- [ ] Test account switching functionality with a sysadmin user
- [ ] Verify regular users don't see the account switcher
- [ ] Test that account scoping works correctly for both sysadmins and regular users

## Session Management

The feature uses session storage for the selected account ID. No special session migration is needed as:

1. Existing sessions will continue to work normally
2. The `selected_account_id` session key is only set when a sysadmin uses the switcher
3. Regular users are unaffected

## Rollback Plan

If the feature needs to be rolled back:

1. **Quick Fix**: Set feature flag to disable the account switcher in the view
2. **Code Rollback**: The changes are minimal and can be easily reverted:
   - Remove the account switcher from the navbar
   - Revert the AccountScoped concern to the previous logic
   - Remove the account switching controller

## Monitoring

After deployment, monitor for:

- Any errors in the account switching controller
- Performance impact of the additional session checks
- User feedback on the new functionality

## Feature Flag Option

If desired, a feature flag could be added:

```ruby
# In ApplicationController or a concern
def account_switching_enabled?
  Rails.application.config.account_switching_enabled != false
end
```

Then in the view:
```erb
<% if current_user&.sysadmin? && account_switching_enabled? %>
  <!-- Account switcher content -->
<% end %>
```