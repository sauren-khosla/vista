import os

root = os.path.abspath(defines.get('root', '.'))
files = [os.path.join(root, 'dist', 'Vista.app')]
symlinks = {'Applications': '/Applications'}
format = 'UDZO'
filesystem = 'HFS+'
volume_name = 'Vista'
icon = os.path.join(root, 'Assets', 'Vista.icns')
background = os.path.join(root, 'packaging', 'background.png')
window_rect = ((200, 120), (660, 430))
icon_locations = {'Vista.app': (185, 225), 'Applications': (475, 225)}
icon_size = 96
text_size = 13
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
# Do not set FinderInfo on the signed app bundle; it invalidates strict verification.
hide_extensions = []
default_view = 'icon-view'
include_icon_view_settings = True
include_list_view_settings = False
