require 'test_helper'

class CreateEditTest < ActiveSupport::TestCase
  fixtures :accounts, :projects

  before do
    @edit = create(:create_edit)
  end

  it 'test_undo_fails_with_no_editor' do
    proc { @edit.do_undo }.must_raise ActsAsEditable::NoEditorAccountError
    @edit.target.reload
    @edit.target.deleted.must_equal false
  end

  it 'test_undo_works_with_editor' do
    @edit.target.deleted.must_equal false
    @edit.target.editor_account = accounts(:admin)
    @edit.do_undo
    @edit.target.reload
    @edit.target.deleted.must_equal true
  end

  it 'test_redo_fails_with_no_editor' do
    @edit.target.editor_account = accounts(:admin)
    @edit.do_undo
    @edit.target.editor_account = nil
    @edit.target.deleted.must_equal true
    proc { @edit.do_redo }.must_raise ActsAsEditable::NoEditorAccountError
    @edit.target.reload
    @edit.target.deleted.must_equal true
  end

  it 'test_redo_works_with_editor' do
    @edit.target.editor_account = accounts(:admin)
    @edit.do_undo
    @edit.target.deleted.must_equal true
    @edit.do_redo
    @edit.target.reload
    @edit.target.deleted.must_equal false
  end
end