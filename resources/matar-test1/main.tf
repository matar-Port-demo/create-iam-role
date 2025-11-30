provider "google" {
  project = "12354"
}

resource "google_storage_bucket" "bucket" {
  name          = "matar-test1"
  location      = "us-central1"
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = false
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

