provider "google" {
  project = "12345"
}

resource "google_storage_bucket" "bucket" {
  name          = "test-one-self-service"
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

