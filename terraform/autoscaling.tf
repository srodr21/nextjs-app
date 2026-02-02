# =============================================================================
# Auto Scaling Configuration
# =============================================================================
# Auto scaling automatically adjusts the number of ECS tasks based on demand.
# This ensures your app can handle traffic spikes while minimizing costs.
#
# Scaling triggers:
# - CPU utilization > 70% → Scale out (add tasks)
# - Memory utilization > 80% → Scale out
# - CPU/Memory drops → Scale in (remove tasks)

# -----------------------------------------------------------------------------
# Auto Scaling Target
# -----------------------------------------------------------------------------
# Registers the ECS service with Application Auto Scaling

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# -----------------------------------------------------------------------------
# CPU-based Auto Scaling
# -----------------------------------------------------------------------------
# Scale based on average CPU utilization across all tasks

resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "${var.project_name}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = var.cpu_target_value      # Target 70% CPU
    scale_in_cooldown  = var.scale_in_cooldown     # Wait 5 min before scaling in
    scale_out_cooldown = var.scale_out_cooldown    # Wait 1 min before scaling out
  }
}

# -----------------------------------------------------------------------------
# Memory-based Auto Scaling
# -----------------------------------------------------------------------------
# Scale based on average memory utilization across all tasks

resource "aws_appautoscaling_policy" "ecs_memory" {
  name               = "${var.project_name}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = var.memory_target_value   # Target 80% memory
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}

# -----------------------------------------------------------------------------
# Request Count Scaling (Optional)
# -----------------------------------------------------------------------------
# Scale based on ALB request count per target
# Useful when you know your tasks can handle X requests each

resource "aws_appautoscaling_policy" "ecs_requests" {
  name               = "${var.project_name}-request-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.main.arn_suffix}/${aws_lb_target_group.main.arn_suffix}"
    }

    target_value       = 1000  # Scale when each task gets 1000 requests/min
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}

# -----------------------------------------------------------------------------
# Scheduled Scaling (Optional)
# -----------------------------------------------------------------------------
# Pre-scale for known traffic patterns (e.g., business hours, sales events)
# Uncomment and customize as needed

# Scale up in the morning (business hours)
# resource "aws_appautoscaling_scheduled_action" "scale_up_morning" {
#   name               = "${var.project_name}-scale-up-morning"
#   service_namespace  = aws_appautoscaling_target.ecs.service_namespace
#   resource_id        = aws_appautoscaling_target.ecs.resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
#   schedule           = "cron(0 8 * * ? *)"  # 8 AM UTC daily
#
#   scalable_target_action {
#     min_capacity = 4
#     max_capacity = var.max_capacity
#   }
# }

# Scale down in the evening
# resource "aws_appautoscaling_scheduled_action" "scale_down_evening" {
#   name               = "${var.project_name}-scale-down-evening"
#   service_namespace  = aws_appautoscaling_target.ecs.service_namespace
#   resource_id        = aws_appautoscaling_target.ecs.resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
#   schedule           = "cron(0 20 * * ? *)"  # 8 PM UTC daily
#
#   scalable_target_action {
#     min_capacity = var.min_capacity
#     max_capacity = var.max_capacity
#   }
# }
