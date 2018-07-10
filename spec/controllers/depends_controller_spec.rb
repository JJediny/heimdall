require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.
#
# Also compared to earlier versions of this generator, there are no longer any
# expectations of assigns and templates rendered. These features have been
# removed from Rails core in Rails 5, but can be added back in via the
# `rails-controller-testing` gem.

RSpec.describe DependsController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # Depend. As you add validations to Depend, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    FactoryBot.build(:dependency).attributes
  }

  let(:invalid_attributes) {
    FactoryBot.build(:invalid_dependency).attributes
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # DependsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  context 'Editor is logged in' do
    let(:user) { FactoryBot.create(:editor) }
    before do
      sign_in user
    end

    before(:each) do
      @profile = create :profile, created_by: user
    end

    describe 'POST #create' do
      context 'with valid params' do
        it 'creates a new Depend' do
          expect {
            post :create, params: { profile_id: @profile.id, depend: valid_attributes }, session: valid_session
          }.to change { @profile.reload.depends.count }.by(1)
        end

        it 'redirects to the created depend' do
          post :create, params: { profile_id: @profile.id, depend: valid_attributes }, session: valid_session
          expect(response).to redirect_to(edit_profile_url(@profile))
        end
      end

      context 'with invalid params' do
        it "returns a success response (i.e. to display the 'new' template)" do
          post :create, params: { profile_id: @profile.id, depend: invalid_attributes }, session: valid_session
          expect(response).to_not be_success
          expect(response).to redirect_to(edit_profile_url(@profile))
        end
      end
    end

    describe 'DELETE #destroy' do
      it 'destroys the requested depend' do
        depend = @profile.depends.create! valid_attributes
        expect {
          delete :destroy, params: { profile_id: @profile.id, id: depend.to_param }, session: valid_session
        }.to change { @profile.reload.depends.count }.by(-1)
      end

      it 'redirects to the depends list' do
        depend = @profile.depends.create! valid_attributes
        delete :destroy, params: { profile_id: @profile.id, id: depend.to_param }, session: valid_session
        expect(response).to redirect_to(edit_profile_url(@profile))
      end
    end
  end
end
