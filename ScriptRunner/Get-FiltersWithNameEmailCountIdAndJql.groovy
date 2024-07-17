import com.atlassian.jira.bc.JiraServiceContextImpl
import com.atlassian.jira.bc.filter.SearchRequestService
import com.atlassian.jira.component.ComponentAccessor
import groovy.xml.MarkupBuilder

def searchRequestService = ComponentAccessor.getComponent(SearchRequestService)
def userManager = ComponentAccessor.getUserManager()

// Define a list of users to fetch filters for
def users = [
    "user1","user2"
]

def totalFilterCount = 0
def writer = new StringWriter()
def markup = new MarkupBuilder(writer)

markup.html {
    head {
        meta(charset: 'utf-8')
        meta(name: 'viewport', content: 'width=device-width, initial-scale=1')
        title('Filters owned by users migrating to Jira Cloud')
        link(href: 'https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css', rel: 'stylesheet', integrity: 'sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH', crossorigin: 'anonymous')
    }
    body(class: 'container mt-5') {
        div(class: 'd-flex align-items-center mb-3') {
            img(src: 'https://www.gravatar.com/avatar/e302bb766577b65086df45701519eb67?d=mm&s=48', class: 'me-3')
            h1('Filters owned by users migrating to Jira Cloud:')
        }
        users.each { username ->
            def user = userManager.getUserByName(username)
            if (user) {
                def serviceContext = new JiraServiceContextImpl(user)
                def ownedFilters = searchRequestService.getOwnedFilters(user)
                totalFilterCount += ownedFilters.size()
            }
        }
        h2("Total Filters: ${totalFilterCount}")
        users.each { username ->
            def user = userManager.getUserByName(username)
            if (user) {
                def serviceContext = new JiraServiceContextImpl(user)
                def ownedFilters = searchRequestService.getOwnedFilters(user)
                def email = user.getEmailAddress()
                def filterCount = ownedFilters.size()

                h3("${user.getDisplayName()} (${filterCount} filters)")
                if (ownedFilters.isEmpty()) {
                    p("No filters found for ${user.displayName}")
                } else {
                    table(class: 'table table-striped table-bordered') {
                        thead(class: 'thead-dark') {
                            tr {
                                th('Filter Name')
                                th('Filter ID')
                                th('Email')
                                th('Query')
                            }
                        }
                        tbody {
                            ownedFilters.each { filter ->
                                tr {
                                    td(filter.getName())
                                    td(filter.getId())
                                    td(email)
                                    td(filter.getQuery().getQueryString())
                                }
                            }
                        }
                    }
                }
            } else {
                p("User ${username} not found")
            }
        }
        script(src: 'https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js', integrity: 'sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz', crossorigin: 'anonymous')
    }
}

return writer.toString()
