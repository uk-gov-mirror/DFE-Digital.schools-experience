Given("I am on the {string} page") do |string|
  path_for(string).tap do |p|
    visit(p)
    expect(page.current_path).to eql(p)
  end
  make_inputs_opaque if opaquify_inputs?
end

Then("the page's main header should be {string}") do |string|
  expect(page).to have_css("h1", text: string)
end

Then("there should be a section titled {string}") do |string|
  expect(page).to have_css('section > h2.govuk-heading-m', text: string)
end

Then("the page should have a heading called {string}") do |string|
  expect(page).to have_css("h1.govuk-fieldset__heading", text: string)
end
