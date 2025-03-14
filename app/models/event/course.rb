# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: events
#
#  id                               :integer          not null, primary key
#  applicant_count                  :integer          default(0)
#  application_closing_at           :date
#  application_conditions           :text
#  application_opening_at           :date
#  applications_cancelable          :boolean          default(FALSE), not null
#  automatic_assignment             :boolean          default(FALSE), not null
#  cost                             :string
#  description                      :text
#  display_booking_info             :boolean          default(TRUE), not null
#  external_applications            :boolean          default(FALSE)
#  globally_visible                 :boolean
#  hidden_contact_attrs             :text
#  location                         :text
#  maximum_participants             :integer
#  minimum_participants             :integer
#  motto                            :string
#  name                             :string
#  notify_contact_on_participations :boolean          default(FALSE), not null
#  number                           :string
#  participant_count                :integer          default(0)
#  participations_visible           :boolean          default(FALSE), not null
#  priorization                     :boolean          default(FALSE), not null
#  required_contact_attrs           :text
#  requires_approval                :boolean          default(FALSE), not null
#  search_column                    :tsvector
#  shared_access_token              :string
#  signature                        :boolean
#  signature_confirmation           :boolean
#  signature_confirmation_text      :string
#  state                            :string(60)
#  teamer_count                     :integer          default(0)
#  training_days                    :decimal(5, 2)
#  type                             :string
#  waiting_list                     :boolean          default(TRUE), not null
#  created_at                       :datetime
#  updated_at                       :datetime
#  application_contact_id           :integer
#  contact_id                       :integer
#  creator_id                       :integer
#  kind_id                          :integer
#  updater_id                       :integer
#
# Indexes
#
#  events_search_column_gin_idx         (search_column) USING gin
#  index_events_on_kind_id              (kind_id)
#  index_events_on_shared_access_token  (shared_access_token)
#

# A course is a specialised Event that has by default applications,
# preconditions and may give a qualification after attending it.
class Event::Course < Event
  # This statement is required because this class would not be loaded otherwise.
  require_dependency "event/course/role/participant"

  self.used_attributes += [:number, :kind_id, :state, :priorization, :group_ids,
    :requires_approval, :display_booking_info, :waiting_list,
    :minimum_participants]

  self.role_types = [Event::Role::Leader,
    Event::Role::AssistantLeader,
    Event::Role::Cook,
    Event::Role::Helper,
    Event::Role::Treasurer,
    Event::Role::Speaker,
    Event::Course::Role::Participant]

  self.supports_applications = true

  self.kind_class = Event::Kind

  # Used for Event::CourseResource
  attr_accessor :leaders

  belongs_to :kind

  validates :kind_id, presence: true, if: -> { used_attributes.include?(:kind_id) }

  after_initialize :make_participations_visible_to_participants

  def label_detail
    label = used_attributes.include?(:kind_id) ? "#{kind.short_name} " : ""
    "#{label}#{number} #{group_names}"
  end

  # Does this event provide qualifications
  def qualifying?
    kind_id? && kind.qualifying?
  end

  # The date on which qualification obtained in this course start
  def qualification_date
    @qualification_date ||= last_finish_or_start_at
  end

  # True when qualifications are ready to be displayed to participants.
  # Overridden in wagons
  def qualifications_visible?
    qualifying? && qualification_date < Time.zone.today
  end

  def start_date
    @start_date ||= dates.first.start_at.to_date
  end

  def minimum_age
    kind&.minimum_age
  end

  def required_attrs
    used_attributes.include?(:kind_id) ? [:kind_id] : []
  end

  private

  def make_participations_visible_to_participants
    self.participations_visible = true if new_record?
  end

  def last_finish_or_start_at
    last_date = dates.max_by(&:start_at)
    (last_date.finish_at || last_date.start_at).to_date
  end
end
