require 'test_helper'

describe 'ProjectTagsController' do
  describe 'index' do
    it 'should show the current projects tags and related projects' do
      project1 = create(:project, name: 'Red')
      project2 = create(:project, name: 'Apple')
      project3 = create(:project, name: 'Blue')
      tag = create(:tag, name: 'color')
      create(:tagging, tag: tag, taggable: project1)
      create(:tagging, tag: tag, taggable: project3)
      get :index, project_id: project1.to_param
      assert_response :success
      assert_select "#related_project_#{project1.to_param}", 0
      assert_select "#related_project_#{project2.to_param}", 0
      assert_select "#related_project_#{project3.to_param}", 1
      response.body.must_match 'color'
    end
  end

  describe 'create' do
    it 'should require a current user' do
      project = create(:project)
      login_as nil
      post :create, project_id: project.to_param, tag_name: 'scrumptious'
      assert_response :unauthorized
      project.reload.tag_list.must_equal ''
    end

    it 'should disallow non-managers from editing the project tag list' do
      project = create(:project)
      create(:permission, target: project, remainder: true)
      login_as create(:account)
      post :create, project_id: project.to_param, tag_name: 'luscious'
      assert_response :unauthorized
      project.reload.tag_list.must_equal ''
    end

    it 'should persist tags' do
      project = create(:project)
      login_as create(:account)
      post :create, project_id: project.to_param, tag_name: 'tasty'
      assert_response :ok
      project.reload.tag_list.must_equal 'tasty'
    end

    it 'should gracefully handle attempting to add the same tag twice' do
      project = create(:project)
      project.tag_list = 'zesty'
      login_as create(:account)
      post :create, project_id: project.to_param, tag_name: 'zesty'
      assert_response :ok
      project.reload.tag_list.must_equal 'zesty'
    end

    it 'should gracefully handle attempting to add garbage' do
      project = create(:project)
      login_as create(:account)
      post :create, project_id: project.to_param, tag_name: '$π@µµé®'
      assert_response :unprocessable_entity
      project.reload.tag_list.must_equal ''
    end
  end

  describe 'destroy' do
    it 'should require a current user' do
      project = create(:project)
      create(:tagging, taggable: project, tag: create(:tag, name: 'shiny'))
      login_as nil
      delete :destroy, project_id: project.to_param, id: 'shiny'
      assert_response :unauthorized
      project.reload.tag_list.must_equal 'shiny'
    end

    it 'should disallow non-managers from editing the project tag list' do
      project = create(:project)
      create(:tagging, taggable: project, tag: create(:tag, name: 'matte'))
      create(:permission, target: project, remainder: true)
      login_as create(:account)
      delete :destroy, project_id: project.to_param, id: 'matte'
      assert_response :unauthorized
      project.reload.tag_list.must_equal 'matte'
    end

    it 'should persist tags' do
      project = create(:project)
      create(:tagging, taggable: project, tag: create(:tag, name: 'glossy'))
      login_as create(:account)
      delete :destroy, project_id: project.to_param, id: 'glossy'
      assert_response :ok
      project.reload.tag_list.must_equal ''
    end
  end

  describe 'related' do
    it 'should show the current projects related projects' do
      project1 = create(:project, name: 'Red')
      project2 = create(:project, name: 'Apple')
      project3 = create(:project, name: 'Blue')
      tag = create(:tag, name: 'color')
      create(:tagging, tag: tag, taggable: project1)
      create(:tagging, tag: tag, taggable: project3)
      get :related, project_id: project1.to_param
      assert_response :success
      assert_select "#related_project_#{project1.to_param}", 0
      assert_select "#related_project_#{project2.to_param}", 0
      assert_select "#related_project_#{project3.to_param}", 1
      response.body.must_match 'color'
    end
  end

  describe 'status' do
    it 'should return how many tags can be added' do
      project = create(:project)
      create(:tagging, taggable: project, tag: create(:tag, name: 'glossy'))
      login_as create(:account)
      get :status, project_id: project.to_param
      assert_response :ok
      resp = JSON.parse(response.body)
      remaining = Tag::MAX_ALLOWED_PER_PROJECT - 1
      resp[0].must_equal remaining
      resp[1].must_equal I18n.t('tags.number_remaining', count: remaining, word: I18n.t('tags.tag').pluralize)
    end
  end
end