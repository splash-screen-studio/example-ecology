# Monetization & Rewards

Ethical monetization strategies for Verdant Basin (2025).

## Philosophy

**Core Principle**: Monetization enhances fun, status, and community — it never gates core gameplay or creates pay-to-win advantages.

Verdant Basin is an ecology simulation about observation, discovery, and connection. Monetization should:
- Reward engagement, not spending
- Offer cosmetic/convenience value, never gameplay power
- Respect young players and their parents
- Be transparent about costs

---

## Ethical Guidelines

### Do

- Use clear, upfront pricing (show Robux AND approximate USD)
- Offer meaningful free progression
- Make purchases permanent or clearly recurring
- Respect spending limits set by parents
- Allow players to earn premium currency through gameplay

### Don't

- Create artificial scarcity ("Buy now or miss forever!")
- Use obfuscated pricing (nested currencies)
- Gate story content behind purchases
- Pressure spending with timers or FOMO
- Target children specifically with manipulative design

### Child Safety (2025 Requirements)

- Parental controls allow spending limits
- High spend notifications at $100, $250, $500
- By 2026: Age verification required for chat
- COPPA/GDPR-K compliance for under-13 users

---

## Revenue Streams

### 1. Game Passes (One-Time Purchases)

Permanent perks that enhance experience without creating advantage.

| Pass | Price | Description |
|------|-------|-------------|
| **Ecologist's Journal** | 149 R$ (~$1.50) | Visual field guide, tracks discoveries |
| **Night Vision** | 249 R$ (~$2.50) | See clearly at night (cosmetic filter) |
| **Extended Reach** | 149 R$ (~$1.50) | Slightly larger interaction range |
| **Lifeweave Attunement** | 499 R$ (~$5.00) | Visualize ecological connections |
| **Multiple Characters** | 349 R$ (~$3.50) | Create up to 3 saved characters |

**Pricing Strategy**:
- Keep most passes under 500 R$
- Premium "bundle" pass at 999 R$ for all cosmetics
- Never lock story or places behind passes

### 2. Developer Products (Consumables)

Repeatable purchases for convenience, never advantage.

| Product | Price | Description |
|---------|-------|-------------|
| **Quick Teleport** | 25 R$ | Instant return to Lifeweave Stone |
| **Snapshot Frame** | 10 R$ | Save a screenshot with custom frame |
| **Donation** | 50-500 R$ | Direct support, displayed in credits |

**Note**: These should be earnable through gameplay too.

### 3. Experience Subscriptions (Recurring)

Monthly subscriptions with clear value.

| Tier | Price | Benefits |
|------|-------|----------|
| **Basin Explorer** | 99 R$/mo | Exclusive cosmetics, early access to new places |
| **Master Ecologist** | 249 R$/mo | All above + behind-scenes dev updates |

**Subscription Ethics**:
- All subscriptions auto-renew (Roblox requirement)
- Clear cancellation instructions
- Benefits continue until billing cycle ends
- Never lock core features behind subscription

### 4. Premium Payouts

Earn from Roblox Premium subscribers playing your game.

**How it works**:
- Premium members generate payouts based on engagement time
- Distributed monthly based on share of Premium play
- Requires developer to have Premium subscription

**To maximize**:
- Create engaging, long-session content
- Reward returning players
- Build community features that encourage time spent

### 5. In-Game Currency (Ecology Points)

Free currency earned through gameplay.

**Earning Methods**:
| Action | Points |
|--------|--------|
| New species discovered | 50 |
| Quest completed | 100-500 |
| Daily login | 25 |
| Help another player | 10 |
| Reach new place | 200 |

**Spending Options**:
- Cosmetic accessories
- Character customization
- Decorative items for personal space
- Donations to other players

**Conversion**: NO direct Robux-to-Points conversion. This prevents pay-to-win and keeps in-game economy meaningful.

---

## Rewards Systems

### Leaderboards

Use OrderedDataStore for global rankings.

```lua
-- src/server/Rewards/LeaderboardService.luau
local DataStoreService = game:GetService("DataStoreService")
local discoveryBoard = DataStoreService:GetOrderedDataStore("Discoveries_v1")

local function updateDiscoveryCount(playerId, count)
    discoveryBoard:SetAsync(tostring(playerId), count)
end

local function getTopDiscoverers(count)
    local pages = discoveryBoard:GetSortedAsync(false, count)
    return pages:GetCurrentPage()
end
```

**Leaderboard Types**:
| Board | Metric | Reset |
|-------|--------|-------|
| Top Discoverers | Species found | Never |
| Weekly Explorers | Distance traveled | Weekly |
| Helpful Ecologists | Players assisted | Monthly |

**Ethics**: Leaderboards should celebrate achievement, not spending.

### Badges

Achievement recognition with no purchase requirement.

| Badge | Requirement |
|-------|-------------|
| First Steps | Complete tutorial |
| Keen Observer | Discover 10 species |
| Basin Explorer | Visit all Verdant Basin areas |
| Lifeweave Touched | Witness ecological cascade |
| Friend of the Wild | Help 10 animals |
| Cross-Plains Traveler | Visit Driftplain |

### Daily/Weekly Rewards

Free rewards for consistent play.

```lua
local function getDailyReward(consecutiveDays)
    local rewards = {
        [1] = { points = 25 },
        [2] = { points = 50 },
        [3] = { points = 75, cosmetic = "Leaf Pin" },
        [7] = { points = 200, title = "Dedicated" },
        [30] = { points = 1000, exclusive = "Golden Compass" },
    }
    return rewards[consecutiveDays] or { points = 25 }
end
```

### Discovery Log

Personal achievement tracking.

```lua
-- Player's discovery journal
local DiscoveryLog = {
    species = {
        { id = "blue_heron", firstSeen = timestamp, location = "Basin Lake" },
        { id = "marsh_frog", firstSeen = timestamp, location = "Reed Beds" },
    },
    behaviors = {
        { id = "heron_fishing", witnessed = timestamp },
        { id = "frog_chorus", witnessed = timestamp },
    },
    connections = {
        { id = "heron_frog_predation", discovered = timestamp },
    },
}
```

---

## DevEx Economics

### Current Rates (September 2025+)

| Metric | Value |
|--------|-------|
| Exchange Rate | $0.0038 per Robux |
| Minimum Cashout | 30,000 Robux = ~$114 |
| Platform Fee | 30% on transactions |
| Frequency | Once per month |

### Revenue Projection

Assume 1,000 DAU, 5% conversion rate:
- 50 purchasers × 200 R$ average = 10,000 R$ gross
- After 30% fee = 7,000 R$ net
- DevEx = ~$26.60/day = ~$800/month

This is modest — focus on engagement and community building first.

---

## Parental Controls Integration

### Spending Limits

Parents can set monthly caps. Respect these programmatically:

```lua
-- Check if purchase would exceed parent-set limit
local function canPurchase(player, robuxAmount)
    -- Roblox handles this automatically, but we can add
    -- our own soft warnings
    if robuxAmount > 500 then
        showConfirmation(player, "This is a larger purchase. Are you sure?")
    end
    return true
end
```

### Clear Pricing Display

Always show both Robux and approximate real money:

```lua
local function formatPrice(robux)
    local usd = robux * 0.0125  -- Approximate purchase rate
    return string.format("%d R$ (~$%.2f)", robux, usd)
end
```

### Purchase Confirmation

For any purchase over 100 R$:
1. Show clear description of what's being purchased
2. Show price in Robux and USD
3. Require explicit confirmation
4. Offer 24-hour refund for accidental purchases

---

## Anti-Patterns to Avoid

### Loot Boxes / Gacha

**Never** use randomized rewards that cost real money.
- Violates child safety principles
- Legally questionable in many jurisdictions
- Damages player trust

### Artificial Scarcity

**Never** use:
- "Only 100 left!"
- "Disappears in 24 hours!"
- Limited-time exclusive gameplay items

Exception: Seasonal cosmetics that return next year are acceptable.

### Pay-to-Win

**Never** sell:
- Faster progression
- Better tools/abilities
- Access to stronger species
- Story skips

### Energy Systems

**Never** use:
- "Wait 4 hours or pay to continue"
- Limited daily actions without payment
- Cooldown-skip purchases

---

## Implementation Roadmap

### Phase 1: Foundation (Launch)
- Free-to-play core experience
- 2-3 cosmetic game passes
- Ecology Points system
- Basic badges

### Phase 2: Expansion
- Add subscription tier
- Expand cosmetic options
- Implement leaderboards
- Premium Payouts optimization

### Phase 3: Community
- Player-to-player gifting
- Community goals with group rewards
- Creator credits/donations
- Seasonal events (free rewards focus)

---

## File Structure

```
src/
  server/
    Monetization/
      GamePassService.luau    -- Pass verification
      ProductService.luau     -- Consumable handling
      SubscriptionService.luau -- Recurring billing
    Rewards/
      PointsService.luau      -- In-game currency
      LeaderboardService.luau -- Rankings
      BadgeService.luau       -- Achievements
      DailyRewards.luau       -- Login bonuses
  shared/
    MonetizationConfig.luau   -- Prices, products
    RewardsConfig.luau        -- Point values, badges
```

---

## Sources

- [Roblox Monetization Documentation](https://create.roblox.com/docs/production/monetization)
- [2025 Monetization Playbook](https://www.primalcam.com/post/the-2025-roblox-monetization-playbook-subscriptions-immersive-ads-avatar-commerce-more)
- [DevEx Rates (Sept 2025)](https://en.help.roblox.com/hc/en-us/articles/27984458742676-Earned-Robux-Earned-Robux-Balance-and-DevEx-Rates)
- [Experience Subscriptions](https://create.roblox.com/docs/production/monetization/subscriptions)
- [Parental Controls](https://en.help.roblox.com/hc/en-us/articles/30428310121620-Parental-Controls-Overview)
- [Roblox Safety Center](https://corp.roblox.com/safety)
- [CHI 2025: Child Safety & Monetization on Roblox](https://dl.acm.org/doi/10.1145/3706598.3713170)
- [Gamepasses & Dev Products Guide](https://boostroom.com/blog/monetization-for-creators-gamepasses-dev-products)
