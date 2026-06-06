with open('lib/features/dms/presentation/components/channel_details_modal.dart', 'r') as f:
    content = f.read()

content = content.replace('Widget _buildHeader(Channel channel, ColorScheme colors)', 'Widget _buildHeader(Channel channel, AppPalette colors)')
content = content.replace('Widget _buildTabBar(ColorScheme colors, int memberCount)', 'Widget _buildTabBar(AppPalette colors, int memberCount)')

with open('lib/features/dms/presentation/components/channel_details_modal.dart', 'w') as f:
    f.write(content)
