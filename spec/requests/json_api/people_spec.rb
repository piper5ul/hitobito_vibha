require 'swagger_helper'

RSpec.describe 'json_api/people', type: :request do

  let(:'X-TOKEN') { service_tokens(:permitted_top_layer_token).token }
  let(:token) { service_tokens(:permitted_top_layer_token).token }
  let(:include) { [] }

  # manually created schema inspired by: https://github.com/superiorlu/jsonapi-swagger/blob/master/lib/generators/jsonapi/swagger/templates/swagger.rb.erb
  @@person_schema =
    { type: :object,
      properties: {
        data: {
          type: :object,
          properties: {
            id: { type: :string, description: 'ID'},
            type: { type: :string, enum: ['people'], default: 'people'},
            attributes: {
              type: :object,
              properties: {
                first_name: { type: :string },
                last_name: { type: :string }
              },
              description: 'Person attributes'
            }
          }
        }
      }
    }

  path '/api/people' do

    # add pagination
    # add filter for updated_at

    get('list people') do
      parameter({
        name: 'include',
        in: :query,
        required: false,
        explode: false,
        schema: {
          type: :array,
          enum: [
            'phone_numbers',
            'social_accounts',
            'additional_emails',
            'roles',
          ],
          nullable: true
        }
      })

      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/vnd.json+api' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(200, 'successful') do
        let(:include) { %w(phone_numbers social_accounts additional_emails roles) }
        run_test!
      end
    end
  end

  path '/api/people/{id}' do
    let(:id) { people(:bottom_member).id }
    parameter name: :id, in: :path, type: :string

    get('fetch person') do
      parameter({
        name: 'include',
        in: :query,
        required: false,
        explode: false,
        schema: {
          type: :array,
          enum: [
            'phone_numbers',
            'social_accounts',
            'additional_emails',
            'roles',
          ],
          nullable: true
        }
      })

      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/vnd.json+api' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(200, 'successful') do
        let(:include) { %w(phone_numbers social_accounts additional_emails roles) }
        run_test!
      end
    end

    patch('update person') do
      parameter name: :data, in: :body, schema: @@person_schema

      response(200, 'successful') do
        let(:data) do
          { data: {
              id: id,
              type: 'people',
              attributes:
              { first_name: 'Bobby' }
            }
          }
        end

        after do |example|
          example.metadata[:response][:content] = {
            'application/vnd.json+api' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end
end
