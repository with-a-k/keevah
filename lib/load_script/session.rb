require "logger"
require "pry"
require "capybara"
require 'capybara/poltergeist'
require "faker"
require "active_support"
require "active_support/core_ext"

module LoadScript
  class Session
    include Capybara::DSL
    attr_reader :host
    def initialize(host = nil)
      Capybara.default_driver = :poltergeist
      @host = host || "http://localhost:3000"
    end

    def logger
      @logger ||= Logger.new("./log/requests.log")
    end

    def session
      @session ||= Capybara::Session.new(:poltergeist)
    end

    def run
      while true
        run_action(actions.sample)
      end
    end

    def run_action(name)
      benchmarked(name) do
        send(name)
      end
    rescue Capybara::Poltergeist::TimeoutError
      logger.error("Timed out executing Action: #{name}. Will continue.")
    end

    def benchmarked(name)
      logger.info "Running action #{name}"
      start = Time.now
      val = yield
      logger.info "Completed #{name} in #{Time.now - start} seconds"
      val
    end

    def actions
      [:browse_loan_requests, 
       :logged_in_browse_loan_requests,
       :sign_up_as_lender,
       :sign_up_as_borrower, 
       :make_a_loan,
       :make_a_loan_request,
       :browse_categories,
       :browse_in_category]
    end

    def log_in(email="demo+horace@jumpstartlab.com", pw="password")
      log_out
      session.visit host
      session.click_link("Login")
      session.fill_in("session_email", with: email)
      session.fill_in("session_password", with: pw)
      session.click_link_or_button("Log In")
    end

    def log_in_as_borrower(email="kingguysemail@under.net", pw="password")
      log_out
      session.visit host
      session.click_link("Login")
      session.fill_in("session_email", with: email)
      session.fill_in("session_password", with: pw)
      session.click_link_or_button("Log In")
    end

    def browse_loan_requests
      session.visit "#{host}/browse?page=#{rand(33400).to_s}"
      session.all(".lr-about").sample.click
    end

    def logged_in_browse_loan_requests
      log_in
      session.visit "#{host}/browse?page=#{rand(33400).to_s}"
      session.all(".lr-about").sample.click
    end

    def log_out
      session.visit host
      if session.has_content?("Log out")
        session.find("#logout").click
      end
    end

    def new_user_name
      "#{Faker::Name.name} #{Time.now.to_i}"
    end

    def new_user_email(name)
      "TuringPivotBots+#{name.split.join}@gmail.com"
    end

    def sign_up_as_lender(name = new_user_name)
      log_out
      session.find("#sign-up-dropdown").click
      session.find("#sign-up-as-lender").click
      session.within("#lenderSignUpModal") do
        session.fill_in("user_name", with: name)
        session.fill_in("user_email", with: new_user_email(name))
        session.fill_in("user_password", with: "password")
        session.fill_in("user_password_confirmation", with: "password")
        session.click_link_or_button "Create Account"
      end
    end

    def sign_up_as_borrower(name = new_user_name)
      log_out
      session.find("#sign-up-dropdown").click
      session.find("#sign-up-as-borrower").click
      session.within("#borrowerSignUpModal") do
        session.fill_in("user_name", with: name)
        session.fill_in("user_email", with: new_user_email(name))
        session.fill_in("user_password", with: "password")
        session.fill_in("user_password_confirmation", with: "password")
        session.click_link_or_button "Create Account"
      end
    end

    def make_a_loan_request
      log_in_as_borrower
      session.click_link_or_button "Create Loan Request"
      session.within("#loanRequestModal") do
        session.fill_in("loan_request_title", with: "#{Faker::Commerce.product_name}")
        session.fill_in("loan_request_description", with: "#{Faker::Company.catch_phrase}")
        session.find("#loan_request_requested_by_date").set("06/01/2016")
        session.find("#loan_request_repayment_begin_date").set("06/01/2016")
        session.fill_in("loan_request_amount", with: "#{(rand(10)*10 + 10).to_s}")
        session.click_link_or_button "Submit"
      end
    end

    def make_a_loan
      log_in
      session.visit "#{host}/browse?page=#{rand(33400).to_s}"
      session.all(".lr-about").sample.click
      session.click_link_or_button "Contribute $25"
      session.visit "#{host}/cart"
      session.click_link_or_button "Transfer Funds"
    end

    def browse_categories
      log_out
      session.visit "#{host}/categories"
      session.click_link_or_button categories.sample
    end

    def browse_in_category
      log_out
      session.visit "#{host}/categories/#{rand(11).to_s}?page=#{rand(10).to_s}"
      session.all(".lr-about").sample.click
    end

    def categories
      ["Agriculture",
      "Education",
      "Water and Sanitation",
      "Youth",
      "Conflict Zones",
      "Transportation",
      "Housing",
      "Banking and Finance",
      "Manufacturing",
      "Food and Nutrition",
      "Vulnerable Groups"]
    end
  end
end
