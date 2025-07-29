import subprocess
import os

def get_commit_list(repo_path, branch="main"):
    """Returns a list of commit SHAs from the specified branch."""
    try:
        os.chdir(repo_path)
        commits = subprocess.check_output(
            ["git", "rev-list", branch],
            stderr=subprocess.DEVNULL
        ).decode().splitlines()
        return commits
    except subprocess.CalledProcessError as e:
        print(f"Error accessing {repo_path}: {e}")
        return []

def compare_commit_history(azure_repo_path, github_repo_path, branch="main"):
    print(f"\n🔍 Comparing branch '{branch}' between:")
    print(f"   Azure Repo:  {azure_repo_path}")
    print(f"   GitHub Repo: {github_repo_path}")

    azure_commits = get_commit_list(azure_repo_path, branch)
    github_commits = get_commit_list(github_repo_path, branch)

    if not azure_commits or not github_commits:
        print("❌ Failed to retrieve commit history from one or both repos.")
        return

    missing = set(azure_commits) - set(github_commits)

    if not missing:
        print("✅ All Azure DevOps commits are present in GitHub.")
    else:
        print(f"❌ {len(missing)} commit(s) from Azure are missing in GitHub:")
        for commit in list(missing)[:5]:
            print(f"   - {commit}")
        if len(missing) > 5:
            print(f"   ... and {len(missing) - 5} more.")

# === Example usage ===
if __name__ == "__main__":
    # Adjust these paths and branch name
    azure_repo_path = "/path/to/local/azure/repo"
    github_repo_path = "/path/to/local/github/repo"
    branch = "main"

    compare_commit_history(azure_repo_path, github_repo_path, branch)
