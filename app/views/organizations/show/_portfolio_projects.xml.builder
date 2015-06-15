xml = xml_instance

xml.portfolio_projects do
  @projects.each do |pro|
    tms = pro.best_analysis.try(:twelve_month_summary)
    ptms = pro.best_analysis.try(:previous_twelve_month_summary)
    commits_diff = ptms.try(:commits_difference).to_i
    committers_diff = ptms.try(:committers_difference).to_i

    xml.project do
      xml.name pro.name
      xml.activity project_activity_text(pro, false)
      xml.primary_language (pro.main_language || "N/A")
      xml.i_use_this pro.user_count
      xml.community_rating "#{pro.rating_average.to_f.round(1)}"
      xml.twelve_mo_activity_and_year_on_year_change do
        xml.commits tms.try(:commit_count).to_i
        xml.change_in_commits commits_diff

        if commits_diff != 0 && ptms.commit_count.to_f != 0
          xml.percentage_change_in_commits (commits_diff.to_f.abs/ptms.commit_count.to_f.abs * 100).to_i
        end

        xml.contributors tms.try(:committer_count).to_i
        xml.change_in_contributors committers_diff

        if committers_diff != 0 && ptms.committer_count.to_f != 0
          xml.percentage_change_in_committers (committers_diff.to_f.abs/ptms.committer_count.to_f.abs * 100).to_i
        end
      end
    end
  end
  xml.detailed_page_url "/orgs/#{org.url_name}/projects"
end