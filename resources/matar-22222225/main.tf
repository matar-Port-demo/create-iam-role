provider "google" {
  project = "21341"
  region  = "us-central1"
}

resource "google_container_cluster" "cluster" {
  name     = "matar-22222225"
  location = "us-central1"
  
  # We remove default node pool to create a custom one
  remove_default_node_pool = true
  initial_node_count       = 1
  
  # Network configuration
  network    = "default"
  subnetwork = "default"
  
  # Enable basic auth (for demo purposes - in production use more secure methods)
  master_auth {
    username = ""
    password = ""
    
    client_certificate_config {
      issue_client_certificate = false
    }
  }
  
  # Node pool configuration
  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 100
    disk_type    = "pd-standard"
    image_type   = "COS_CONTAINERD"
    
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    
    preemptible = false
  }
  
  # Enable logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  
  # Disable legacy ABAC
  enable_legacy_abac = false
  
  # Resource labels
  resource_labels = {
    environment = "production"
    managed_by  = "terraform"
  }
}

# Custom node pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.cluster.name}-node-pool"
  location   = "us-central1"
  cluster    = google_container_cluster.cluster.name
  node_count = 3
  
  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 100
    disk_type    = "pd-standard"
    image_type   = "COS_CONTAINERD"
    
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    
    preemptible = false
    
    labels = {
      environment = "production"
    }
  }
  
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

output "cluster_name" {
  value = google_container_cluster.cluster.name
}

output "cluster_endpoint" {
  value = google_container_cluster.cluster.endpoint
}

output "cluster_region" {
  value = "us-central1"
}

