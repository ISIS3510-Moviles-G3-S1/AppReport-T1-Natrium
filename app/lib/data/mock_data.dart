import '../models/listing.dart';
import '../models/item_detail.dart';
import '../models/seller.dart';
import '../models/profile_models.dart';

class MockData {
  static final featuredListings = [
    Listing(
      id: 1,
      name: "Vintage Levi's Denim Jacket",
      price: 25,
      size: "M",
      condition: "Good",
      category: "Jackets",
      color: "Blue",
      style: "Casual",
      seller: "Sofia R.",
      rating: 4.8,
      image:
          "https://images.unsplash.com/photo-1601333144130-8cbb312386b6?w=400&h=500&fit=crop",
      saved: false,
    ),
    Listing(
      id: 2,
      name: "Floral Summer Dress",
      price: 18,
      size: "S",
      condition: "Like New",
      category: "Dresses",
      color: "Multicolor",
      style: "Boho",
      seller: "Maria G.",
      rating: 5.0,
      image:
          "https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=400&h=500&fit=crop",
      saved: true,
    ),
    Listing(
      id: 3,
      name: "Cream Knit Sweater",
      price: 20,
      size: "L",
      condition: "Good",
      category: "Tops",
      color: "Cream",
      style: "Cozy",
      seller: "Emma T.",
      rating: 4.6,
      image:
          "https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400&h=500&fit=crop",
      saved: false,
    ),
    Listing(
      id: 4,
      name: "Black Slim Trousers",
      price: 15,
      size: "M",
      condition: "Fair",
      category: "Bottoms",
      color: "Black",
      style: "Smart Casual",
      seller: "Ana L.",
      rating: 4.3,
      image:
          "https://images.unsplash.com/photo-1594938298603-c8148c4b4086?w=400&h=500&fit=crop",
      saved: false,
    ),
    Listing(
      id: 5,
      name: "Puffer Winter Jacket",
      price: 40,
      size: "XL",
      condition: "Like New",
      category: "Jackets",
      color: "Green",
      style: "Sporty",
      seller: "Laura P.",
      rating: 4.9,
      image:
          "https://images.unsplash.com/photo-1548126032-079a0fb0099d?w=400&h=500&fit=crop",
      saved: false,
    ),
  ];

  static final browseListings = [
    ...featuredListings,
    Listing(
      id: 6,
      name: "Silk Blouse Ivory",
      price: 22,
      size: "S",
      condition: "Good",
      category: "Tops",
      color: "Ivory",
      style: "Elegant",
      seller: "Chloe M.",
      rating: 4.7,
      image:
          "https://images.unsplash.com/photo-1485518882345-15568b007407?w=400&h=500&fit=crop",
      tags: ["Elegant", "Silk", "Evening"],
      saved: false,
    ),
    Listing(
      id: 7,
      name: "Canvas Tote Bag",
      price: 10,
      size: "One Size",
      condition: "Like New",
      category: "Accessories",
      color: "Natural",
      style: "Casual",
      seller: "Ines R.",
      rating: 4.5,
      image:
          "https://images.unsplash.com/photo-1544816155-12df9643f363?w=400&h=500&fit=crop",
      tags: ["Eco", "Casual", "Bag"],
      saved: true,
    ),
    Listing(
      id: 8,
      name: "High-Waist Jeans",
      price: 28,
      size: "M",
      condition: "Good",
      category: "Bottoms",
      color: "Blue",
      style: "Casual",
      seller: "Nora B.",
      rating: 4.4,
      image:
          "https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=400&h=500&fit=crop",
      tags: ["Denim", "Casual", "Classic"],
      saved: false,
    ),
    Listing(
      id: 9,
      name: "Striped Linen Shirt",
      price: 16,
      size: "L",
      condition: "Good",
      category: "Tops",
      color: "White",
      style: "Casual",
      seller: "Kai O.",
      rating: 4.6,
      image:
          "https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=400&h=500&fit=crop",
      tags: ["Linen", "Summer", "Stripe"],
      saved: false,
    ),
  ];

  static final itemDetails = [
    ItemDetail(
      id: 1,
      name: "Vintage Levi's Denim Jacket",
      price: 25,
      size: "M",
      condition: "Good",
      category: "Jackets",
      color: "Blue",
      style: "Casual",
      seller: Seller(
        name: "Sofia R.",
        university: "UCM Madrid",
        rating: 4.8,
        sales: 12,
        avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Sofia",
        verified: true,
      ),
      aiScore: 87,
      description:
          "Classic vintage Levi's denim jacket in good condition. Minor wear on the cuffs adds to its character. Perfect for layering in autumn and spring.",
      images: [
        "https://images.unsplash.com/photo-1601333144130-8cbb312386b6?w=600&h=700&fit=crop",
        "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=300&h=300&fit=crop",
        "https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=300&h=300&fit=crop",
      ],
      tags: ["Casual", "Vintage", "Denim", "Layering", "Autumn"],
      exchangeType: "sell",
    ),
    ItemDetail(
      id: 2,
      name: "Floral Summer Dress",
      price: 18,
      size: "S",
      condition: "Like New",
      category: "Dresses",
      color: "Multicolor",
      style: "Boho",
      seller: Seller(
        name: "Maria G.",
        university: "UPM Madrid",
        rating: 5.0,
        sales: 7,
        avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Maria",
        verified: true,
      ),
      aiScore: 95,
      description:
          "Beautiful floral summer dress worn only twice. Lightweight fabric, perfect for festivals or campus events. No stains or damage.",
      images: [
        "https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=600&h=700&fit=crop",
        "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=300&h=300&fit=crop",
        "https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=300&h=300&fit=crop",
      ],
      tags: ["Boho", "Summer", "Floral", "Festival", "Light"],
      exchangeType: "swap",
    ),
    ItemDetail(
      id: 3,
      name: "Cream Knit Sweater",
      price: 20,
      size: "L",
      condition: "Good",
      category: "Tops",
      color: "Cream",
      style: "Cozy",
      seller: Seller(
        name: "Emma T.",
        university: "Complutense",
        rating: 4.6,
        sales: 5,
        avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Emma",
        verified: false,
      ),
      aiScore: 82,
      description:
          "Soft cream knit sweater from Zara. Gently used, no pilling. Great for cold evenings or cozy study sessions.",
      images: [
        "https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=600&h=700&fit=crop",
        "https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=300&h=300&fit=crop",
        "https://images.unsplash.com/photo-1556821840-3a63f15732ce?w=300&h=300&fit=crop",
      ],
      tags: ["Knitwear", "Cozy", "Autumn", "Zara", "Soft"],
      exchangeType: "sell",
    ),
    ItemDetail(
      id: 4,
      name: "Black Slim Trousers",
      price: 15,
      size: "M",
      condition: "Fair",
      category: "Bottoms",
      color: "Black",
      style: "Smart Casual",
      seller: Seller(
        name: "Ana L.",
        university: "UAM",
        rating: 4.3,
        sales: 3,
        avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Ana",
        verified: false,
      ),
      aiScore: 72,
      description:
          "Slim-fit black trousers, slightly faded from washing but still presentable. Perfect for office or smart casual looks.",
      images: [
        "https://images.unsplash.com/photo-1594938298603-c8148c4b4086?w=600&h=700&fit=crop",
        "https://images.unsplash.com/photo-1509631179647-0177331693ae?w=300&h=300&fit=crop",
        "https://images.unsplash.com/photo-1584370848010-d7fe6bc767ec?w=300&h=300&fit=crop",
      ],
      tags: ["Smart", "Office", "Classic", "Black", "Slim"],
      exchangeType: "donate",
    ),
    ItemDetail(
      id: 5,
      name: "Puffer Winter Jacket",
      price: 40,
      size: "XL",
      condition: "Like New",
      category: "Jackets",
      color: "Green",
      style: "Sporty",
      seller: Seller(
        name: "Laura P.",
        university: "UC3M",
        rating: 4.9,
        sales: 20,
        avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Laura",
        verified: true,
      ),
      aiScore: 93,
      description:
          "Warm army-green puffer jacket. Worn only once last winter. Excellent insulation, water-resistant outer shell.",
      images: [
        "https://images.unsplash.com/photo-1548126032-079a0fb0099d?w=600&h=700&fit=crop",
        "https://images.unsplash.com/photo-1507680434567-5739c80be1ac?w=300&h=300&fit=crop",
        "https://images.unsplash.com/photo-1544441893-675973e31985?w=300&h=300&fit=crop",
      ],
      tags: ["Winter", "Sporty", "Warm", "Puffer", "Green"],
      exchangeType: "sell",
    ),
  ];

  static final similarItems = [
    (
      id: 3,
      name: "Cream Knit Sweater",
      price: 20.0,
      image:
          "https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=300&h=300&fit=crop",
    ),
    (
      id: 5,
      name: "Puffer Winter Jacket",
      price: 40.0,
      image:
          "https://images.unsplash.com/photo-1548126032-079a0fb0099d?w=300&h=300&fit=crop",
    ),
    (
      id: 6,
      name: "Silk Blouse Ivory",
      price: 22.0,
      image:
          "https://images.unsplash.com/photo-1485518882345-15568b007407?w=300&h=300&fit=crop",
    ),
    (
      id: 8,
      name: "High-Waist Jeans",
      price: 28.0,
      image:
          "https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=300&h=300&fit=crop",
    ),
  ];

  static const categories = [
    "All",
    "Tops",
    "Bottoms",
    "Jackets",
    "Dresses",
    "Accessories",
  ];
  static const sizes = ["All", "XS", "S", "M", "L", "XL"];
  static const conditions = ["All", "Like New", "Good", "Fair"];
  static const colorFilters = [
    ("All", 0xFFe5e7eb),
    ("Blue", 0xFF3b82f6),
    ("Black", 0xFF111827),
    ("Cream", 0xFFfef3c7),
    ("Green", 0xFF16a34a),
    ("White", 0xFFf9fafb),
    ("Multicolor", 0xFFef4444),
  ];

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
  static const exchangeTypes = [
    ("sell", "Sell", "List for a price"),
    ("swap", "Swap", "Trade for another item"),
    ("donate", "Donate", "Give it for free"),
  ];
}
