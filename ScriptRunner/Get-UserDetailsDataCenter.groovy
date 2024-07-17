import com.atlassian.jira.component.ComponentAccessor

// Get the current logged-in user
def user = ComponentAccessor.jiraAuthenticationContext.loggedInUser

// Fetch the user directory service
def userManager = ComponentAccessor.userManager

// Fetch user details
def userDetails = userManager.getUserByKey(user.key)

// Prepare the response
def response = [
    "Username": user.username,
    "Display Name": user.displayName,
    "Email": user.emailAddress,
    "Account ID": user.key
]

// Print the response
return response
