####################################################
# /spec/features
####################################################
require 'feature_helper'

feature 'Dashboard Discovery', js: true do
  let(:exp) { ::Experience::Dashboard::DiscoveryExp.new }
  let(:user) { create(:user, :with_active_plan) }

  before do
    Timecop.freeze(Time.now.end_of_month)
    login_as user
    elasticsearch_setup_index('royal_event_events')
    bill1; bill_action1; sponsor1
    bill2; bill_action2; sponsor2
    event1; event2
    elasticsearch_refresh
  end
  after { Timecop.return }

  let(:items_selector) { '.discovery-items-block' }
  let(:subscription1) {  create(:royal_event_subscription, user: user) }
  let(:bill1) { create(:federal_bill) }
  let(:bill_action1) { create(:bill_action, bill: bill1) }
  let(:sponsor1) { create(:bill_sponsor, bill: bill1) }
  let(:event1) do
    create(
      :royal_event_event,
      subscription: subscription1,
      strategy_data: {
        keyword: subscription1.required_inputs['keyword'],
        highlighted_text: 'highlight1',
        bill_id: bill1.id
      },
      created_at: 1.week.ago,
    )
  end
  let(:subscription2) { create(:royal_event_subscription, user: user) }
  let(:bill2) { create(:federal_bill) }
  let(:bill_action2) { create(:bill_action, bill: bill2) }
  let(:sponsor2) { create(:bill_sponsor, bill: bill2) }
  let(:event2) do
    create(
      :royal_event_event,
      subscription: subscription2,
      strategy_data: {
        keyword: subscription2.required_inputs['keyword'],
        highlighted_text: 'highlight2',
        bill_id: bill2.id
      },
      created_at: 2.days.ago,
    )
  end

  scenario 'lists all keywords' do
    exp.visit_dashboard_discovery

    keyword_subs = user.
      royal_event_subscriptions.
      enabled.
      where(subscribable_slug: :keyword)

    within exp.keywords_selector do
      keyword_subs.each do |sub|
        expect(page).to have_content(sub.required_inputs['keyword'])
      end
    end
  end

  scenario 'filtering by keywords' do
    exp.visit_dashboard_discovery
    exp.toggle_keyword_checkbox subscription1.required_inputs['keyword']

    within items_selector do
      expect(page).to have_content('highlight1')
      expect(page).not_to have_content('highlight2')
    end

    exp.visit_dashboard_discovery
    exp.toggle_keyword_checkbox subscription2.required_inputs['keyword']

    within items_selector do
      expect(page).not_to have_content('highlight1')
      expect(page).to have_content('highlight2')
    end
  end

  scenario 'filtering by text' do
    exp.visit_dashboard_discovery
    exp.filter_by_text 'highlight1'

    within items_selector do
      expect(page).to have_content('highlight1')
      expect(page).not_to have_content('highlight2')
    end
  end

  scenario 'filtering by date range' do
    exp.visit_dashboard_discovery

    from = 4.days.ago.strftime('%m/%d/%Y')
    exp.filter_by_date_range from: from

    within items_selector do
      expect(page).not_to have_content('highlight1')
      expect(page).to have_content('highlight2')
    end

    exp.visit_dashboard_discovery
    to = 5.days.ago.strftime('%m/%d/%Y')
    exp.filter_by_date_range to: to

    within items_selector do
      expect(page).not_to have_content('highlight2')
      expect(page).to have_content('highlight1')
    end
  end

  scenario 'save to topic' do
    create(:topic, owner: user, name: 'Default')
    screenshot_and_open_image
    exp.visit_dashboard_discovery
    expect do
      exp.save_topic 0
    end.to change(TopicItem, :count).by(1)
  end
end
####################################################
# /spec/support/experience/dashboard/discovery_exp
####################################################
module Experience
  module Dashboard
    class DiscoveryExp < Base
      def visit_dashboard_discovery
        visit dashboard_discovery_path
      end

      def toggle_keyword_checkbox(keyword)
        within keywords_selector do
          find('.royal-checkbox__label', text: keyword).click
        end
      end

      def filter_by_text(text)
        fill_in 'discovery_search_fulltext', with: text
      end

      def filter_by_date_range(opts)
        opts = opts.with_indifferent_access
        if opts[:from]
          input_start = find('#start_date', visible: :all)
          input_start.click
          input_start.set(opts[:from])
        end
        if opts[:to]
          input_end = find('#end_date', visible: :all)
          input_end.click
          input_end.set(opts[:to])
        end
      end

      def save_topic(index)
        wrappers = all('.discovery-checkbox-block .royal-checkbox__square')
        wrappers[index].click

        find('.save-to-topic').click
        wait_for_stable_dom
        first('.dashboard-topic-saver__topics-block input').click
        click_button 'Save'
        wait_for_stable_dom
      end

      def keywords_selector
        selector = '.discovery-search-form__keywords-block'
        selector << '.discovery-search-form-component'

        selector
      end
    end
  end
end
