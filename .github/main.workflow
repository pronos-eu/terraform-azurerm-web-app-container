workflow "Terraform" {
  on = "push"
  resolves = ["terraform-fmt"]
}

action "terraform-fmt" {
  uses = "innovationnorway/github-action-terraform@master"
  args = ["fmt", "-check", "-list", "-no-color"]
}

workflow "Semantic Release" {
  on = "push"
  resolves = ["semantic-release"]
}

action "filter-master-branch" {
  uses = "actions/bin/filter@master"
  args = "branch master"
}

action "semantic-release" {
  uses = "innovationnorway/github-action-semantic-release@master"
  needs = "filter-master-branch"
  secrets = ["GH_TOKEN"]
}
