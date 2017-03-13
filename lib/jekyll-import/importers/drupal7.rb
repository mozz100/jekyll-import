require 'jekyll-import/importers/drupal_common'

module JekyllImport
  module Importers
    class Drupal7 < Importer
      include DrupalCommon
      extend DrupalCommon::ClassMethods

      def self.build_query(prefix, types)
        types = types.join("' OR n.type = '")
        types = "n.type = '#{types}'"

        query = <<EOS
                SELECT n.nid,
                       n.title,
                       fdb.body_value,
                       fdb.body_summary,
                       n.created,
                       n.status,
                       n.type,
                       (SELECT GROUP_CONCAT(td.name SEPARATOR '|') FROM taxonomy_term_data td, taxonomy_index ti WHERE ti.tid = td.tid AND ti.nid = n.nid) AS 'tags',
                       fm.uri AS 'image1uri',
                       fm2.uri AS 'image2uri',
                       ua.alias AS 'alias'
                FROM #{prefix}node AS n
                LEFT JOIN #{prefix}field_data_body AS fdb ON fdb.entity_id = n.nid AND fdb.entity_type = 'node'
                LEFT JOIN #{prefix}field_data_field_image AS fdfi ON fdfi.entity_id = n.nid and fdfi.entity_type = 'node'
                LEFT JOIN #{prefix}file_managed AS fm on fm.fid = fdfi.field_image_fid
                LEFT JOIN #{prefix}field_data_field_image2 AS fdfi2 ON fdfi2.entity_id = n.nid and fdfi2.entity_type = 'node'
                LEFT JOIN #{prefix}file_managed AS fm2 on fm2.fid = fdfi2.field_image2_fid
                LEFT JOIN #{prefix}url_alias AS ua on ua.source = CONCAT('node/', n.nid)
                WHERE (#{types})
EOS

        return query
      end

      def self.aliases_query(prefix)
        "SELECT source, alias FROM #{prefix}url_alias WHERE source = ?"
      end

      def self.post_data(sql_post_data)
        content = sql_post_data[:body_value].to_s
        summary = sql_post_data[:body_summary].to_s
        tags = (sql_post_data[:tags] || '').downcase.strip
        images = []
        image1 = sql_post_data[:image1uri].to_s
        image2 = sql_post_data[:image2uri].to_s
        images.push('old/' + image1.gsub('public://', '')) if image1.length > 0
        images.push('old/' + image2.gsub('public://', '')) if image2.length > 0

        data = {
          'excerpt' => summary,
          'tags' => tags.split('|'),
          'images' => images,
          
        }

        if [213, 102, 96, 87, 77, 46].include? sql_post_data[:nid]
          data['is_fave'] = true
        end

        return data, content
      end

    end
  end
end
