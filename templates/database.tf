provider "google" {
  project = "{{ project_id }}"
  region  = "{{ region }}"
}

resource "google_sql_database_instance" "database" {
  name             = "{{ database_name }}"
  database_version = "{{ database_version }}"
  region           = "{{ region }}"
  
  settings {
    tier = "{{ database_tier }}"
    
    backup_configuration {
      enabled                        = true
      start_time                     = "{{ backup_schedule }}"
      point_in_time_recovery_enabled = true
    }
    
    ip_configuration {
      ipv4_enabled = false
      private_network = "projects/{{ project_id }}/global/networks/default"
    }
    
    database_flags {
      name  = "max_connections"
      value = "100"
    }
  }
  
  deletion_protection = false
}

resource "google_sql_database" "database" {
  name     = "{{ database_name }}"
  instance = google_sql_database_instance.database.name
}

resource "google_sql_user" "database_user" {
  name     = "{{ database_user }}"
  instance = google_sql_database_instance.database.name
  password = "{{ database_password }}"
}

output "database_name" {
  value = google_sql_database.database.name
}

output "database_instance_name" {
  value = google_sql_database_instance.database.name
}

output "database_connection_name" {
  value = google_sql_database_instance.database.connection_name
}

