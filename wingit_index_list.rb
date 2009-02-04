include Wx
include IconLoader

class WingitIndexList < Panel

	attr_accessor :unstaged, :staged, :diff


	def initialize(parent)
		super(parent, ID_ANY)

		@unstaged = ListBox.new(self, ID_ANY, nil, nil, nil, LB_EXTENDED|LB_SORT)
		@staged = ListBox.new(self, ID_ANY, nil, nil, nil, LB_EXTENDED|LB_SORT)

		@toolbar = ToolBar.new(self, ID_ANY, nil, nil, TB_HORIZONTAL|NO_BORDER|TB_NODIVIDER)
		@toolbar.set_tool_bitmap_size(Size.new(16,16))
		@toolbar.add_tool(101, "Stage all", get_icon("folder_add.png"), "Stage all")
		@toolbar.add_tool(102, "Stage", get_icon("page_add.png"), "Stage file")
		@toolbar.add_separator
		@toolbar.add_tool(103, "Unstage", get_icon("page_delete.png"), "Unstage file")
		@toolbar.add_tool(104, "Unstage all", get_icon("folder_delete.png"), "Unstage all")
		@toolbar.realize

		unstaged_label = StaticText.new(self, ID_ANY, "Unstaged")
		staged_label = StaticText.new(self, ID_ANY, "Staged to commit")
		unstaged_label.set_background_colour(Colour.new(255, 192, 192))
		staged_label.set_background_colour(Colour.new(128, 255, 128))

		box = BoxSizer.new(VERTICAL)
		box.add(unstaged_label, 0, EXPAND)
		box.add(@unstaged, 1, EXPAND)
		box.add(@toolbar, 0, ALIGN_CENTER_HORIZONTAL)
		box.add(staged_label, 0, EXPAND)
		box.add(@staged, 1, EXPAND)
		self.set_sizer(box)

		evt_listbox(@unstaged.get_id, :on_unstaged_click)
		evt_listbox(@staged.get_id, :on_staged_click)
		evt_listbox_dclick(@unstaged.get_id, :on_unstaged_double_click)
		evt_listbox_dclick(@staged.get_id, :on_staged_double_click)

		update
	end


	def update()
		others = `git ls-files --others --exclude-standard`
		deleted = `git ls-files --deleted`
		modified = `git ls-files --modified`
		staged = `git ls-files --stage`

		@unstaged.clear
		@staged.clear

		deleted = deleted.split("\n")
		deleted.each {|file| @unstaged.append(file + " (D)", [file, "D"])}
		others.split("\n").each {|file| @unstaged.append(file + " (N)", [file, "N"])}
		modified.split("\n").each {|file| @unstaged.append(file + " (M)", [file, "M"]) unless deleted.include?(file)}
		staged.split("\n").each do |line|
			(info, file) = line.split("\t")
			diff = `git diff --cached -- #{file}`
			@staged.append(file) unless diff.empty?
		end
	end


	def on_unstaged_click(event)
		@diff ||= self.get_parent.diff
		@staged.deselect(-1) # Clear the other box's selection

		i = event.get_index
		(file, change) = @unstaged.get_item_data(i)

		case change
		when "N"
			val = `cat #{file}`
			@diff.change_value(val)
		when "M", "D"
			val = `git diff -- #{file}`
			@diff.set_diff(val)
		else
			@diff.clear
		end
	end


	def on_staged_click(event)
		@diff ||= self.get_parent.diff
		@unstaged.deselect(-1) # Clear the other box's selection

		i = event.get_index
		file = @staged.get_string(i)

		val = `git diff --cached -- #{file}`
		@diff.set_diff(val)
	end


	def on_unstaged_double_click(event)
		@diff.clear
		(file, change) = @unstaged.get_item_data(event.get_index)
		case change
		when "D"
			`git rm --cached #{file}`
		else
			`git add #{file}`
		end
		update
	end


	def on_staged_double_click(event)
		@diff.clear
		file = @staged.get_string(event.get_index)
		`git reset #{file}`
		update
	end

end
