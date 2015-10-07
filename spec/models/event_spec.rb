# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: events
#
#  id                          :integer          not null, primary key
#  type                        :string
#  name                        :string           not null
#  number                      :string
#  motto                       :string
#  cost                        :string
#  maximum_participants        :integer
#  contact_id                  :integer
#  description                 :text
#  location                    :text
#  application_opening_at      :date
#  application_closing_at      :date
#  application_conditions      :text
#  kind_id                     :integer
#  state                       :string(60)
#  priorization                :boolean          default(FALSE), not null
#  requires_approval           :boolean          default(FALSE), not null
#  created_at                  :datetime
#  updated_at                  :datetime
#  participant_count           :integer          default(0)
#  application_contact_id      :integer
#  external_applications       :boolean          default(FALSE)
#  applicant_count             :integer          default(0)
#  teamer_count                :integer          default(0)
#  signature                   :boolean
#  signature_confirmation      :boolean
#  signature_confirmation_text :string
#  creator_id                  :integer
#  updater_id                  :integer
#

require 'spec_helper'

describe Event do

  let(:event) { events(:top_course) }

  context '#participations' do

    let(:event) { events(:top_event) }

    subject do
      Fabricate(Event::Role::Leader.name.to_sym, participation:  Fabricate(:event_participation, event: event))
      Fabricate(Event::Role::Participant.name.to_sym, participation:  Fabricate(:event_participation, event: event))
      p = Fabricate(:event_participation, event: event)
      Fabricate(Event::Role::Participant.name.to_sym, participation: p)
      Fabricate(Event::Role::Participant.name.to_sym, participation: p, label: 'Irgendwas')
      event.reload
    end
    its(:participant_count) { should == 2 }
  end


  context '#application_possible?' do

    context 'without opening and closing dates' do
      it 'is open without maximum participant' do
        is_expected.to be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        is_expected.not_to be_application_possible
      end

      it 'is open when maximum participants is not yet reached' do
        subject.maximum_participants = 20
        subject.participant_count = 19
        is_expected.to be_application_possible
      end
    end

    context 'with closing date in the future' do
      before { subject.application_closing_at = Date.today + 1 }

       it 'is open without maximum participant' do
        is_expected.to be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        is_expected.not_to be_application_possible
      end

    end

    context 'with closing date today' do
      before { subject.application_closing_at = Date.today }

      it 'is open without maximum participant' do
        is_expected.to be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        is_expected.not_to be_application_possible
      end
    end

    context 'with closing date in the past' do
      before { subject.application_closing_at = Date.today - 1 }

      it 'is closed without maximum participant' do
        is_expected.not_to be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        is_expected.not_to be_application_possible
      end
    end


    context 'with opening date in the past' do
      before { subject.application_opening_at = Date.today - 1 }

      it 'is open without maximum participant' do
        is_expected.to be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        is_expected.not_to be_application_possible
      end
    end

    context 'with opening date today' do
      before { subject.application_opening_at = Date.today }

      it 'is open without maximum participant' do
        is_expected.to be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        is_expected.not_to be_application_possible
      end
    end

    context 'with opening date in the future' do
      before { subject.application_opening_at = Date.today + 1 }

      it 'is closed without maximum participant' do
        is_expected.not_to be_application_possible
      end
    end

    context 'with opening and closing dates' do
      before do
        subject.application_opening_at = Date.today - 2
        subject.application_closing_at = Date.today + 2
      end

      it 'is open' do
        is_expected.to be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        is_expected.not_to be_application_possible
      end

      it 'is open when maximum participants is not yet reached' do
        subject.maximum_participants = 20
        subject.participant_count = 19
        is_expected.to be_application_possible
      end
    end

    context 'with opening and closing dates in the future' do
      before do
        subject.application_opening_at = Date.today + 1
        subject.application_closing_at = Date.today + 2
      end

      it 'is closed' do
        is_expected.not_to be_application_possible
      end
    end

    context 'with opening and closing dates in the past' do
      before do
        subject.application_opening_at = Date.today - 2
        subject.application_closing_at = Date.today - 1
      end

      it 'is closed' do
        is_expected.not_to be_application_possible
      end
    end
  end

  context 'finders' do

    context '.in_year' do
      context 'one date' do
        before { set_start_finish(event, '2000-01-02') }

        it 'uses dates create_at to determine if event matches' do
          expect(Event.in_year(2000).size).to eq 1
          expect(Event.in_year(2001)).not_to be_present
          expect(Event.in_year(2000).first).to eq event
          expect(Event.in_year('2000').first).to eq event
        end

      end

      context 'starting at last day of year and another date in the following year' do
        before { set_start_finish(event, '2010-12-31 17:00') }
        before { set_start_finish(event, '2011-01-20') }

        it 'finds event in old year' do
          expect(Event.in_year(2010)).to eq([event])
        end

        it 'finds event in following year' do
          expect(Event.in_year(2011)).to eq([event])
        end

        it 'does not find event in past year' do
          expect(Event.in_year(2009)).to be_blank
        end
      end
    end

    context '.upcoming' do
      subject { Event.upcoming }
      it 'does not find past events' do
        set_start_finish(event, '2010-12-31 17:00')
        is_expected.not_to be_present
      end

      it 'does find upcoming event' do
        event.dates.create(start_at: 2.days.from_now, finish_at: 5.days.from_now)
        is_expected.to eq [event]
      end

      it 'does find running event' do
        event.dates.create(start_at: 2.days.ago, finish_at: Time.zone.now)
        is_expected.to eq [event]
      end

      it 'does find event ending at 5 to 12' do
        event.dates.create(start_at: 2.days.ago, finish_at: Time.zone.now.midnight + 23.hours + 55.minutes)
        is_expected.to eq [event]
      end

      it 'does not find event ending at 5 past 12' do
        event.dates.create(start_at: 2.days.ago, finish_at: Time.zone.now.midnight - 5.minutes)
        is_expected.to be_blank
      end

      it 'does find event with only start date' do
        event.dates.create(start_at: 1.day.from_now)
        is_expected.to eq [event]
      end

      it 'does find event with only start date' do
        event.dates.create(start_at: Time.zone.now.midnight + 5.minutes)
        is_expected.to eq [event]
      end
    end
  end

  context 'validations' do
    subject { event }

    it 'is not valid without event_dates' do
      event.dates.clear
      expect(event.valid?).to be_falsey
      expect(event.errors[:dates]).to be_present
    end

    it 'is valid with application closing after opening' do
      subject.application_opening_at = Date.today - 5
      subject.application_closing_at = Date.today + 5
      subject.valid?

      is_expected.to be_valid
    end

    it 'is not valid with application closing before opening' do
      subject.application_opening_at = Date.today - 5
      subject.application_closing_at = Date.today - 6

      is_expected.not_to be_valid
    end

    it 'is valid with application closing and without opening' do
      subject.application_closing_at = Date.today - 6

      is_expected.to be_valid
    end

    it 'is valid with application opening and without closing' do
      subject.application_opening_at = Date.today - 6

      is_expected.to be_valid
    end

    it 'requires groups' do
      subject.group_ids = []

      is_expected.to have(1).error_on(:group_ids)
    end
  end

  context '#init_questions' do
    it 'adds 3 default questions for courses' do
      e = Event::Course.new
      e.init_questions
      expect(e.questions.size).to eq(3)
    end

    it 'does nothing for regular events' do
      e = Event.new
      e.init_questions
      expect(e.questions).to be_blank
    end
  end

  context 'event_dates' do
    let(:e) { event }

    it "should update event_date's start_at time" do
      d = Time.zone.local(2012, 12, 12).to_date
      e.dates.create(label: 'foo', start_at: d, finish_at: d)
      ed = e.dates.first
      e.update_attributes(dates_attributes: { '0' => { start_at_date: d, start_at_hour: 18, start_at_min: 10, id: ed.id } })
      expect(e.dates.first.start_at).to eq(Time.zone.local(2012, 12, 12, 18, 10))
    end

    it "should update event_date's finish_at date" do
      d1 = Time.zone.local(2012, 12, 12).to_date
      d2 = Time.zone.local(2012, 12, 13).to_date
      e.dates.create(label: 'foo', start_at: d1, finish_at: d1)
      ed = e.dates.first
      e.update_attributes(dates_attributes: { '0' => { finish_at_date: d2, id: ed.id } })
      expect(e.dates.first.finish_at).to eq(Time.zone.local(2012, 12, 13, 00, 00))
    end

  end

  context 'participation role labels' do

    let(:event) { events(:top_event) }
    let(:participation) { Fabricate(:event_participation, event: event) }

    it 'should have 2 different labels' do
      Fabricate(Event::Role::Participant.name.to_sym, participation: participation, label: 'Foolabel')
      Fabricate(Event::Role::Participant.name.to_sym, participation: participation, label: 'Foolabel')
      Fabricate(Event::Role::Participant.name.to_sym, participation: participation, label: 'Just label')
      event.reload

      expect(event.participation_role_labels.count).to eq 2
    end

    it 'should have no labels' do
      Fabricate(Event::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: event))
      Fabricate(Event::Role::Participant.name.to_sym, participation: participation)
      event.reload

      expect(event.participation_role_labels.count).to eq 0
    end

  end

  context 'participant and application counts' do
    def create_participation(prio, attrs = { active: true })
      participation_attrs = prio == :prio1 ? { event: event } : { event: another_event }
      application_attrs = prio == :prio1 ? { priority_1: event } : { priority_1: another_event, priority_2: event }

      participation = Fabricate(:event_participation, participation_attrs.merge(attrs))
      participation.create_application!(application_attrs)
      Fabricate(event.class.participant_types.first.name.to_sym, participation: participation)
      participation.save!

      Event::ParticipantAssigner.new(event, participation).add_participant if attrs[:active]
      participation
    end

    def assert_counts(attrs)
      event.reload
      expect(event.participant_count).to eq attrs[:participant]
      expect(event.applicant_count).to eq attrs[:applicant]
    end

    context 'for basic event' do
      let(:event) { events(:top_event) }

      it 'should be zero if no participations/applications available' do
        expect(event.participations.count).to eq 0
        expect(Event::Application.where('priority_2_id = ? OR priority_3_id = ?', event.id, event.id).
          count).to eq 0

        assert_counts(participant: 0, applicant: 0)
      end

      it 'should not count leaders' do
        leader = Fabricate(:event_participation, event: event, active: true)
        Fabricate(Event::Role::Leader.name.to_sym, participation: leader, label: 'Foolabel')

        assert_counts(participant: 0, applicant: 0)
      end

      it 'should count participations with multiple roles in regular event correctly' do
        p = Fabricate(:event_participation, event: event, active: true)

        Fabricate(Event::Role::Cook.name.to_sym, participation: p)
        assert_counts(participant: 0, applicant: 0)

        r = Fabricate(Event::Role::Participant.name.to_sym, participation: p)
        assert_counts(participant: 1, applicant: 1)

        r.destroy
        assert_counts(participant: 0, applicant: 0)
      end
    end

    context 'for course' do
      let(:event) { events(:top_course) }
      let(:another_event) { Event::Course.create!(name: 'Another', group_ids: event.group_ids,
                                          dates: event.dates, kind: event_kinds(:slk)) }

      it 'should count participations with multiple roles in course correctly' do
        p = Fabricate(:event_participation,
                      event: event,
                      active: true,
                      application: Fabricate(:event_application, priority_1: event))

        Fabricate(Event::Role::Cook.name.to_sym, participation: p)
        assert_counts(participant: 0, applicant: 0)

        r = Fabricate(Event::Course::Role::Participant.name.to_sym, participation: p)
        assert_counts(participant: 1, applicant: 1)

        # in courses, participant roles are removed like that
        Event::ParticipantAssigner.new(event, p).remove_participant
        assert_counts(participant: 0, applicant: 1)

        p.destroy!
        assert_counts(participant: 0, applicant: 0)
      end

      it 'should count active prio 1 participations correctly' do
        p = create_participation(:prio1)
        assert_counts(participant: 1, applicant: 1)

        p.destroy!
        assert_counts(participant: 0, applicant: 0)
      end

      it 'should count active prio 2 participations correctly' do
        create_participation(:prio2)
        assert_counts(participant: 1, applicant: 1)
      end

      it 'should count pending prio 1 participations correctly' do
        create_participation(:prio1, active: false)
        assert_counts(participant: 0, applicant: 1)
      end

      it 'should count pending prio 2 participations correctly' do
        create_participation(:prio2, active: false)
        assert_counts(participant: 0, applicant: 0)
      end

      it 'should sum participations/applications correctly' do
        leader = Fabricate(:event_participation, event: event, active: true)
        Fabricate(Event::Role::Leader.name.to_sym, participation: leader, label: 'Foolabel')

        create_participation(:prio1)
        create_participation(:prio2)
        create_participation(:prio1, active: false)
        create_participation(:prio2, active: false)

        assert_counts(participant: 2, applicant: 3)
      end

    end
  end

  context 'destroyed associations' do
    let(:event) { events(:top_course) }

    it 'destroys everything with event' do
      expect do
        expect do
          expect do
            expect do
              expect { event.destroy }.to change { Event.count }.by(-1)
            end.to change { Event::Participation.count }.by(-1)
          end.to change { Event::Role.count }.by(-1)
        end.to change { Event::Date.count }.by(-1)
      end.to change { Event::Question.count }.by(-3)
    end

    it 'keeps destroyed kind' do
      event.kind.destroy
      event.reload

      expect(event.kind).to be_present
    end

    context 'groups' do
      let(:group_one) { groups(:bottom_group_one_one) }
      let(:group_two) { groups(:bottom_group_one_two) }
      let(:event) { Fabricate(:event, groups: [group_one, group_two]) }

      it 'keeps destroyed groups' do
        expect(event.groups.size).to eq(2)

        group_two.destroy
        expect(group_two).to be_deleted
        event.reload

        expect(event.groups.size).to eq(2)
      end
    end

  end


  def set_start_finish(event, start_at)
    start_at = Time.zone.parse(start_at)
    event.dates.create!(start_at: start_at, finish_at: start_at + 5.days)
  end

end
