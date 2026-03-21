import '../models/listing.dart';
import '../models/item_detail.dart';
import '../models/seller.dart';
import '../models/profile_models.dart';

class MockData {
  static final featuredListings = [
    Listing(
      id: '1',
      sellerId: 'seller1',
      title: "Vintage Levi's Denim Jacket",
      price: 25,
      conditionTag: "Good",
      description: "Vintage Levi's denim jacket in good condition",
      sellerName: "Sofia R.",
      rating: 4.8,
      imageName: 'denim_jacket.jpg',
      imagePath: "https://images.unsplash.com/photo-1601333144130-8cbb312386b6?w=400&h=500&fit=crop",
      saved: false,
    ),
    Listing(
      id: '2',
      sellerId: 'seller2',
      title: "Floral Summer Dress",
      price: 18,
      conditionTag: "Like New",
      description: "Beautiful floral summer dress",
      sellerName: "Maria G.",
      rating: 5.0,
      imageName: 'floral_dress.jpg',
      imagePath: "https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=400&h=500&fit=crop",
      saved: true,
    ),
    Listing(
      id: '3',
      sellerId: 'seller3',
      title: "Cream Knit Sweater",
      price: 20,
      conditionTag: "Good",
      description: "Cozy cream knit sweater",
      sellerName: "Emma T.",
      rating: 4.6,
      imageName: 'knit_sweater.jpg',
      imagePath: "https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400&h=500&fit=crop",
      saved: false,
    ),
    Listing(
      id: '4',
      sellerId: 'seller4',
      title: "Black Slim Trousers",
      price: 15,
      conditionTag: "Fair",
      description: "Black slim trousers in fair condition",
      sellerName: "Ana L.",
      rating: 4.3,
      imageName: 'black_trousers.jpg',
      imagePath: "https://images.unsplash.com/photo-1594938298603-c8148c4b4086?w=400&h=500&fit=crop",
      saved: false,
    ),
    Listing(
      id: '5',
      sellerId: 'seller5',
      title: "Puffer Winter Jacket",
      price: 40,
      conditionTag: "Like New",
      description: "Warm puffer winter jacket",
      sellerName: "Laura P.",
      rating: 4.9,
      imageName: 'puffer_jacket.jpg',
      imagePath: "https://images.unsplash.com/photo-1548126032-079a0fb0099d?w=400&h=500&fit=crop",
      saved: false,
    ),
  ];

  static final browseListings = [
    ...featuredListings,
    Listing(
      id: '6',
      sellerId: 'seller6',
      title: "Silk Blouse Ivory",
      price: 22,
      conditionTag: "Good",
      description: "Elegant silk blouse in ivory. Perfect for evening events or formal occasions. No stains, gently used.",
      sellerName: "Chloe M.",
      rating: 4.7,
      imageName: 'silk_blouse.jpg',
      imagePath: "https://images.unsplash.com/photo-1485518882345-15568b007407?w=400&h=500&fit=crop",
      imageURLs: [
        "https://images.unsplash.com/photo-1485518882345-15568b007407?w=600&h=700&fit=crop",
        "https://images.unsplash.com/photo-1485518882345-15568b007407?w=300&h=300&fit=crop",
        "https://images.unsplash.com/photo-1485518882345-15568b007407?w=300&h=300&fit=crop",
      ],
      tags: ["Elegant", "Silk", "Evening"],
      exchangeType: "sell",
    ),
    // 7. Canvas Tote Bag
    ItemDetail(
      id: '7',
      name: "Canvas Tote Bag",
      price: 10.0,
      condition: "Like New",
      seller: Seller(
        name: "Ines R.",
        university: "Complutense",
        rating: 4.5,
        sales: 4,
        avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Ines",
        verified: false,
      ),
      aiScore: 88,
      description: "Eco-friendly canvas tote bag. Great for shopping or daily use. No visible wear.",
      images: [
        "https://images.unsplash.com/photo-1544816155-12df9643f363?w=600&h=700&fit=crop",
        "https://images.unsplash.com/photo-1544816155-12df9643f363?w=300&h=300&fit=crop",
        "https://images.unsplash.com/photo-1544816155-12df9643f363?w=300&h=300&fit=crop",
      ],
      tags: ["Eco", "Casual", "Bag"],
    ),
    // 8. High-Waist Jeans
    ItemDetail(
      id: '8',
      name: "High-Waist Jeans",
      price: 28.0,
      condition: "Good",
      seller: Seller(
        name: "Nora B.",
        university: "UAM",
        rating: 4.4,
        sales: 6,
        avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Nora",
        verified: false,
      ),
      aiScore: 85,
      description: "Classic high-waist jeans. Comfortable fit, no tears or stains. Great for everyday wear.",
      images: [
        "https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=600&h=700&fit=crop",
        "https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=300&h=300&fit=crop",
        "https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=300&h=300&fit=crop",
      ],
      tags: ["Denim", "Casual", "Classic"],
    ),
    // 9. Striped Linen Shirt
    ItemDetail(
      id: '9',
      name: "Striped Linen Shirt",
      price: 16.0,
      condition: "Good",
      seller: Seller(
        name: "Kai O.",
        university: "UC3M",
        rating: 4.6,
        sales: 9,
        avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Kai",
        verified: true,
      ),
      aiScore: 91,
      description: "Lightweight striped linen shirt. Breathable and perfect for summer. No damage, gently used.",
      images: [
        "https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=600&h=700&fit=crop",
        "https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=300&h=300&fit=crop",
        "https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=300&h=300&fit=crop",
      ],
      tags: ["Linen", "Summer", "Stripe"],
    ),
  ];

  static final similarItems = [
    ItemDetail(
      id: '3',
      name: "Cream Knit Sweater",
      price: 20.0,
      condition: "Good",
      seller: Seller(
        name: "Emma T.",
        university: "UPM Madrid",
        rating: 4.6,
        sales: 5,
        avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Emma",
        verified: true,
      ),
      aiScore: 87,
      description: "Cozy cream knit sweater",
      images: [
        "https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=300&h=300&fit=crop",
      ],
      tags: ["Knit", "Winter", "Cozy"],
    ),
    ItemDetail(
      id: '5',
      name: "Puffer Winter Jacket",
      price: 40.0,
      condition: "Like New",
      seller: Seller(
        name: "Laura P.",
        university: "Complutense",
        rating: 4.9,
        sales: 12,
        avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Laura",
        verified: true,
      ),
      aiScore: 92,
      description: "Warm puffer winter jacket",
      images: [
        "https://images.unsplash.com/photo-1548126032-079a0fb0099d?w=300&h=300&fit=crop",
      ],
      tags: ["Winter", "Puffer", "Warm"],
    ),
    ItemDetail(
      id: '6',
      name: "Silk Blouse Ivory",
      price: 22.0,
      condition: "Good",
      seller: Seller(
        name: "Chloe M.",
        university: "UPM Madrid",
        rating: 4.7,
        sales: 8,
        avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Chloe",
        verified: true,
      ),
      aiScore: 90,
      description: "Elegant silk blouse in ivory",
      images: [
        "https://images.unsplash.com/photo-1485518882345-15568b007407?w=300&h=300&fit=crop",
      ],
      tags: ["Silk", "Elegant", "Evening"],
    ),
    ItemDetail(
      id: '8',
      name: "High-Waist Jeans",
      price: 28.0,
      condition: "Good",
      seller: Seller(
        name: "Nora B.",
        university: "UAM",
        rating: 4.4,
        sales: 6,
        avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Nora",
        verified: false,
      ),
      aiScore: 85,
      description: "Classic high-waist jeans",
      images: [
        "https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=300&h=300&fit=crop",
      ],
      tags: ["Denim", "Casual", "Classic"],
    ),
  ];

  // Removed deprecated static fields: categories, sizes, colorFilters

  static const badges = [
    ProfileBadge(
      id: 1,
      emoji: "🛍️",
      name: "First Sale",
      desc: "Sold your first item",
      earned: true,
      xp: 50,
    ),
    ProfileBadge(
      id: 2,
      emoji: "💚",
      name: "5 Items Saved",
      desc: "Saved 5 items from waste",
      earned: true,
      xp: 100,
    ),
    ProfileBadge(
      id: 3,
      emoji: "🌍",
      name: "Eco Hero",
      desc: "Completed 10 sustainable swaps",
      earned: true,
      xp: 200,
    ),
    ProfileBadge(
      id: 4,
      emoji: "📸",
      name: "Photo Pro",
      desc: "Uploaded 5 photos with AI tags",
      earned: true,
      xp: 75,
    ),
    ProfileBadge(
      id: 5,
      emoji: "⭐",
      name: "Top Rated",
      desc: "Received 5 five-star reviews",
      earned: false,
      xp: 150,
    ),
    ProfileBadge(
      id: 6,
      emoji: "🔥",
      name: "Streak Keeper",
      desc: "Active for 7 days in a row",
      earned: false,
      xp: 120,
    ),
    ProfileBadge(
      id: 7,
      emoji: "♻️",
      name: "Swap Master",
      desc: "Completed 20 swaps",
      earned: false,
      xp: 300,
    ),
    ProfileBadge(
      id: 8,
      emoji: "🎖️",
      name: "Campus Legend",
      desc: "Reached Level 10",
      earned: false,
      xp: 500,
    ),
  ];

  static const activityFeed = [
    ActivityItem(
      id: 1,
      type: "sold",
      icon: "🛍️",
      text: "You sold Vintage Levi's Denim Jacket",
      time: "2 hours ago",
      xp: 50,
    ),
    ActivityItem(
      id: 2,
      type: "saved",
      icon: "💚",
      text: "You saved Floral Summer Dress",
      time: "Yesterday",
      xp: 5,
    ),
    ActivityItem(
      id: 3,
      type: "bought",
      icon: "🛒",
      text: "You bought Cream Knit Sweater",
      time: "3 days ago",
      xp: 30,
    ),
    ActivityItem(
      id: 4,
      type: "donated",
      icon: "🎁",
      text: "You donated Black Slim Trousers",
      time: "Last week",
      xp: 75,
    ),
    ActivityItem(
      id: 5,
      type: "badge",
      icon: "🏅",
      text: 'Earned badge "Eco Hero"',
      time: "Last week",
      xp: 200,
    ),
  ];

  static List<MyListing> myListings = [
    MyListing(
      id: 1,
      name: "Vintage Levi's Denim Jacket",
      price: 25,
      status: "Active",
      image:
          "https://images.unsplash.com/photo-1601333144130-8cbb312386b6?w=200&h=200&fit=crop",
    ),
    MyListing(
      id: 3,
      name: "Cream Knit Sweater",
      price: 20,
      status: "Active",
      image:
          "https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=200&h=200&fit=crop",
    ),
    MyListing(
      id: 9,
      name: "Striped Linen Shirt",
      price: 16,
      status: "Sold",
      image:
          "https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=200&h=200&fit=crop",
    ),
  ];

  static const levels = [
    Level(level: 1, name: "Eco Newcomer", minXp: 0),
    Level(level: 2, name: "Green Starter", minXp: 100),
    Level(level: 3, name: "Swap Buddy", minXp: 250),
    Level(level: 4, name: "Eco Explorer", minXp: 500),
    Level(level: 5, name: "Sustainability Star", minXp: 900),
    Level(level: 6, name: "Campus Champion", minXp: 1400),
  ];

  static const int profileXp = 680;
  static const String profileName = "Alex López";
  static const String profileSince = "Sept 2024";
  static const String profileUniversity = "UCM Madrid";
  static const double profileRating = 4.8;
  static const int profileTransactions = 15;
  static const String profileAvatar =
      "https://api.dicebear.com/7.x/avataaars/svg?seed=Alex";

  static const conditionsSell = ["Like New", "Good", "Fair", "Poor"];
  static const sustainabilityTips = [
    "By selling this item, you're preventing it from entering a landfill!",
    "Second-hand fashion saves water and reduces CO₂ emissions.",
    "Every swap saves ~7kg of CO₂ compared to buying new.",
    "You just extended this item's life and earned 50 XP with Eco!",
  ];
  // Removed deprecated static field: exchangeTypes
}
