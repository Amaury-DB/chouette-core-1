class PublicationApiKeysController < ChouetteController
  include PolicyChecker

  requires_feature :manage_publications

  defaults :resource_class => PublicationApiKey, collection_name: :api_keys
  belongs_to :workgroup do
    belongs_to :publication_api
  end

  def create
    create! { [@workgroup, @publication_api]}
  end

  def update
    update! { [@workgroup, @publication_api]}
  end

  def destroy
    destroy! { [@workgroup, @publication_api]}
  end

  def publication_api_key_params
    publication_api_key_params = params.require(:publication_api_key)
    permitted_keys = [:name]
    publication_api_key_params.permit(permitted_keys)
  end
end
