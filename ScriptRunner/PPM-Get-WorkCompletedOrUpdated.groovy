(
  issueFunction in commented("by currentUser()")
  OR issueFunction in workLogged("by currentUser()")
  OR issueFunction in issueUpdated("by currentUser()")
  OR assignee = currentUser()
  OR reporter = currentUser()
)
AND updated >= "2025-01-01"
AND updated <= "2025-12-31"
ORDER BY updated DESC
