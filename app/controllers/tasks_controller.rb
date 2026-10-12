class TasksController < ApplicationController
  DONE_WINDOW = 7.days

  def index
    @shift_task = ShiftTask.current
    @categories = Setting.categories
    @filter = params[:category].presence

    visible = Task.visible_to(current_user)
    scoped = @filter ? visible.where(category: @filter) : visible

    @open_tasks = scoped.where(completed: false).order(priority: :desc, added: :asc, id: :asc).to_a
    @done_tasks = scoped.where(completed: true).where('complete_time >= ?', DONE_WINDOW.ago)
                        .order(complete_time: :desc).to_a
    @category_counts = visible.where(completed: false).group(:category).count
    @done_today = visible.where(completed: true).where('complete_time >= ?', Time.zone.now.beginning_of_day).count
    @member_names = User.where(active: true).order(:name).pluck(:name).uniq
  end

  def create
    task = Task.new(task_params)
    task.added = Time.current
    task.user_add = acting_name
    task.completed = false
    if task.save
      flash[:success] = "Added “#{task.name.truncate(60)}”."
    else
      flash[:danger] = task.errors.full_messages.to_sentence
    end
    redirect_to tasks_path(category: params[:category].presence)
  end

  def edit
    @task = Task.find_by(id: params[:id])
    return redirect_missing unless @task

    @categories = Setting.categories
  end

  def update
    task = Task.find_by(id: params[:id])
    return redirect_missing unless task

    attrs = task_params
    attrs[:priority] = task.priority if task.priority == 2 # Airtable tasks keep their type
    if task.update(attrs)
      flash[:success] = 'Task updated.'
    else
      flash[:danger] = task.errors.full_messages.to_sentence
    end
    redirect_to tasks_path(category: params[:category].presence)
  end

  def destroy
    task = Task.find_by(id: params[:id])
    return redirect_missing unless task

    task.destroy
    flash[:success] = "Deleted “#{task.name.truncate(60)}”."
    redirect_to tasks_path(category: params[:category].presence)
  end

  # One tap marks a task done (or, with check_type=unchecking, not done).
  def checkmark
    task = Task.find_by(id: params[:id])
    return redirect_missing unless task

    checking = params[:check_type] != 'unchecking'
    if checking && task.completed
      flash[:danger] = "#{task.user_complete.presence || 'Someone'} already finished that one."
    elsif !checking && !task.completed
      flash[:danger] = 'That task is already open again.'
    elsif checking
      task.update!(completed: true, user_complete: acting_name, complete_time: Time.current)
      flash[:success] = "Nice! “#{task.name.truncate(60)}” is done."
      flash[:undo_task_id] = task.id
    else
      task.update!(completed: false, user_complete: nil, complete_time: nil)
      flash[:success] = "“#{task.name.truncate(60)}” is back on the list."
    end
    redirect_to tasks_path(category: params[:category].presence)
  end

  # Lets people on a shared login pick whose name goes on their check-offs.
  def checking_as
    name = params[:name].to_s.strip.first(60)
    if name.present?
      cookies[:checking_as] = { value: name, expires: 8.hours }
      flash[:success] = "Got it, #{name}. Your check-offs will show your name for this shift."
    else
      cookies.delete(:checking_as)
    end
    redirect_to tasks_path(category: params[:category].presence)
  end

  private

  def task_params
    {
      name: params[:task_name].to_s.strip,
      description: params[:task_description].to_s.strip,
      category: params[:task_category].presence,
      priority: params[:priority].to_i == 3 ? 3 : 1
    }
  end

  def redirect_missing
    flash[:danger] = 'That task no longer exists.'
    redirect_to tasks_path
  end
end
