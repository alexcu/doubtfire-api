module TutorProjectsHelper
  def unmarked_project_tasks(tutor_unit, tutor)
    tutors_teams    = Team.where(:unit_id => tutor_unit.id, :user_id => tutor.id)
    tutors_projects = Project.includes(:tasks).find(
      TeamMembership.where(:team_id => [tutors_teams.map{|team| team.id}])
      .map{|membership| membership.project_id }
    )

    tutors_projects.map{|project| project.tasks }.flatten.select{|task| task.awaiting_signoff? }
  end

  def user_task_map(tasks)
    user_tasks      = {}

    tasks.each do |task|
      user_for_task = task.project.team_membership.user

      user_tasks[user_for_task] ||= []
      user_tasks[user_for_task] << task
    end

    user_tasks
  end

  def unmarked_tasks(projects)
    projects.map{|project| project.tasks }.flatten.select{|task| task.awaiting_signoff? }
  end

  def user_unmarked_tasks(projects)
    user_task_map(unmarked_tasks(projects))
  end

  def needing_help_tasks(projects)
    projects.map{|project| project.tasks }.flatten.select{|task| task.need_help? && !task.awaiting_signoff }
  end

  def user_needing_help_tasks(projects)
    user_task_map(needing_help_tasks(projects))
  end

  def working_on_it_tasks(projects)
    projects.map{|project| project.tasks }.flatten.select{|task| task.working_on_it? && !task.awaiting_signoff }
  end

  def user_working_on_it_tasks(projects)
    user_task_map(working_on_it_tasks(projects))
  end

  def task_bar_item_class_for_mode(task, progress, mode)
    if mode == :action
      if task.complete?
        "action-complete"
      elsif task.awaiting_signoff?
        "action-awaiting-signoff"
      elsif task.fix_and_resubmit?
        "action-fix-and-resubmit"
      elsif task.fix_and_include?
        "action-fix-and-include"
      elsif task.redo?
        "action-redo"
      elsif task.need_help?
        "action-need-help"
      elsif task.working_on_it?
        "action-working-on-it"
      else
        "action-incomplete"
      end
    else
      if task.complete?
        progress_suffix = progress.to_s.gsub("_", "-")
        "progress-#{progress_suffix}"
      elsif task.awaiting_signoff?
        "action-awaiting-signoff"
      else
        "action-incomplete"
      end
    end
  end

  def task_bar_item(project, task, link, progress, mode, relative_number)
    progress_class  = task_bar_item_class_for_mode(task, progress, :progress)
    action_class    = task_bar_item_class_for_mode(task, progress, :action)

    description_text = (task.task_template.description.nil? or task.task_template.description == "NULL") ? "(No description provided)" : task.task_template.description

    active_class = mode == :progress ? progress_class : action_class
    status_control_partial = render(:partial => "tutor_projects/assessor_task_status_control", :locals => { :task => task })

    link_to(
      task.task_template.abbreviation || relative_number,
      link,
      :rel => "popover",
      :class => "task-progress-item task-#{task.id}-bar-item #{active_class}",
      "data-progress-class" => progress_class,
      "data-action-class"   => action_class,
      "data-original-title" => "#{task.task_template.name}",
      "data-content"        => [
        description_text,
        h(status_control_partial)
      ].join("\n")
    )
  end

  def tasks_progress_bar(project, student, mode=:action)
    tasks = project.assigned_tasks

    progress = project.progress

    raw(tasks.each_with_index.map{|task, i|
      task_bar_item(project, task, tutor_project_student_path(project, student), progress, mode, i + 1)
    }.join("\n"))
  end
end