class ProfileBadge {
  final int id;
  final String emoji;
  final String name;
  final String desc;
  final bool earned;
  final int xp;

  const ProfileBadge({
    required this.id,
    required this.emoji,
    required this.name,
    required this.desc,
    required this.earned,
    required this.xp,
  });
}

class ActivityItem {
  final int id;
  final String type;
  final String icon;
  final String text;
  final String time;
  final int xp;

  const ActivityItem({
    required this.id,
    required this.type,
    required this.icon,
    required this.text,
    required this.time,
    required this.xp,
  });
}

class MyListing {
  final int id;
  final String name;
  final double price;
  final String status; // 'Active' | 'Sold'
  final String image;

  const MyListing({
    required this.id,
    required this.name,
    required this.price,
    required this.status,
    required this.image,
  });
}

class Level {
  final int level;
  final String name;
  final int minXp;

  const Level({required this.level, required this.name, required this.minXp});
}
