import com.atlassian.jira.component.ComponentAccessor
import com.atlassian.jira.bc.filter.SearchRequestService
import com.atlassian.jira.user.ApplicationUser

def searchRequestService = ComponentAccessor.getComponent(SearchRequestService)
def userManager = ComponentAccessor.getUserManager()
def adminUser = userManager.getUserByName("PUT_USERNAME_HERE")  // Change "admin" to your admin username

if (!adminUser) {
    return "Admin user not found"
}

def filters = searchRequestService.getOwnedFilters(adminUser)

filters.each { filter ->
    println "Filter Name: ${filter.getName()}, Filter ID: ${filter.getId()}"
}
