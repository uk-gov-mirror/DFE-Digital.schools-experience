Given("there is a new placement request") do
  @placement_request = FactoryBot.create(:bookings_placement_request, school: @school)
end

Given("I am on the accept placement request page") do
  path = path_for("accept placement request", placement_request_id: @placement_request.id)
  visit(path)
  expect(page.current_path).to eql(path)
end

Then("every row of the booking details list should have a {string} link") do |string|
  within('#booking-details') do
    page.all('div.govuk-summary-list__row').each do |row|
      expect(row).to have_link(string)
    end
  end
end
