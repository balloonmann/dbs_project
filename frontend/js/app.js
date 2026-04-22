// DBS Project — Frontend Logic

const API_BASE = 'http://localhost:3000/api';

let currentUserId = 1;
let currentSection = 'dashboard';
let stocksCache = [];
let portfolioCache = [];
let pnlData = null;
let pnlActiveTab = 'unrealized';

document.addEventListener('DOMContentLoaded', () => {
    initNavigation();
    initTradeForm();
    initPnlTabs();
    loadUsers();

    // Auto-refresh current section every 5 seconds to show live price changes
    setInterval(() => {
        loadSectionData(currentSection);
    }, 5000);
});

// ---------------------------------------------------------------------------
// Navigation
// ---------------------------------------------------------------------------
function initNavigation() {
    document.querySelectorAll('.nav-item').forEach(btn => {
        btn.addEventListener('click', () => {
            navigateTo(btn.dataset.section);
        });
    });
}

function navigateTo(section) {
    currentSection = section;

    document.querySelectorAll('.nav-item').forEach(b => b.classList.remove('active'));
    const activeBtn = document.querySelector(`.nav-item[data-section="${section}"]`);
    if (activeBtn) activeBtn.classList.add('active');

    document.querySelectorAll('.content-section').forEach(s => s.classList.remove('active'));
    const activeSection = document.getElementById(`section-${section}`);
    if (activeSection) activeSection.classList.add('active');

    const titles = {
        dashboard: ['Dashboard', 'Overview of your portfolio performance'],
        portfolio: ['Portfolio', 'Your current stock holdings'],
        trade: ['Trade', 'Buy and sell stocks'],
        analytics: ['Analytics', 'Detailed investment analysis and P&L'],
        transactions: ['Transactions', 'Complete trading history'],
        watchlist: ['Watchlist', 'Stocks you\'re tracking'],
    };
    const [title, subtitle] = titles[section] || ['', ''];
    document.getElementById('page-title').textContent = title;
    document.getElementById('page-subtitle').textContent = subtitle;

    loadSectionData(section);
}

function loadSectionData(section) {
    switch (section) {
        case 'dashboard': loadDashboard(); break;
        case 'portfolio': loadPortfolio(); break;
        case 'trade': loadTradeSection(); break;
        case 'analytics': loadAnalytics(); break;
        case 'transactions': loadTransactions(); break;
        case 'watchlist': loadWatchlist(); break;
    }
}

// ---------------------------------------------------------------------------
// API Helper
// ---------------------------------------------------------------------------
async function apiFetch(endpoint) {
    try {
        const res = await fetch(`${API_BASE}${endpoint}`);
        if (!res.ok) {
            const err = await res.json().catch(() => ({ error: res.statusText }));
            throw new Error(err.error || 'API error');
        }
        return await res.json();
    } catch (err) {
        console.error(`API ${endpoint}:`, err.message);
        return null;
    }
}

async function apiPost(endpoint, body) {
    try {
        const res = await fetch(`${API_BASE}${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body),
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || 'API error');
        return data;
    } catch (err) {
        console.error(`API POST ${endpoint}:`, err.message);
        throw err;
    }
}

// ---------------------------------------------------------------------------
// Users
// ---------------------------------------------------------------------------
async function loadUsers() {
    const users = await apiFetch('/users');
    const select = document.getElementById('user-select');
    select.innerHTML = '';

    if (users && users.length > 0) {
        users.forEach(u => {
            const opt = document.createElement('option');
            opt.value = u.user_id;
            opt.textContent = u.full_name;
            select.appendChild(opt);
        });
        currentUserId = users[0].user_id;
        updateHeaderBalance(users[0].account_balance);
    } else {
        const mockUsers = [
            { user_id: 1, full_name: 'Aditya Sharma', account_balance: 785000 },
            { user_id: 2, full_name: 'Priya Patel', account_balance: 921500 },
            { user_id: 3, full_name: 'Rahul Kumar', account_balance: 1152000 },
            { user_id: 4, full_name: 'Sneha Reddy', account_balance: 648000 },
        ];
        mockUsers.forEach(u => {
            const opt = document.createElement('option');
            opt.value = u.user_id;
            opt.textContent = u.full_name;
            select.appendChild(opt);
        });
        currentUserId = 1;
        updateHeaderBalance(785000);
    }

    select.addEventListener('change', (e) => {
        currentUserId = parseInt(e.target.value);
        const selectedUser = users?.find(u => u.user_id === currentUserId);
        if (selectedUser) updateHeaderBalance(selectedUser.account_balance);
        loadSectionData(currentSection);
    });

    loadDashboard();
}

function updateHeaderBalance(balance) {
    document.getElementById('header-balance').textContent = formatCurrency(balance);
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------
async function loadDashboard() {
    const [portfolio, summary] = await Promise.all([
        apiFetch(`/portfolio/${currentUserId}`),
        apiFetch(`/analytics/summary/${currentUserId}`),
    ]);

    portfolioCache = portfolio || [];
    const sum = summary?.summary || {};
    const holdings = summary?.holdings || portfolio || [];

    const totalInvested = holdings.reduce((a, h) => a + parseFloat(h.cost_basis || 0), 0);
    const currentValue = holdings.reduce((a, h) => a + parseFloat(h.market_value || 0), 0);
    const totalGain = currentValue - totalInvested;
    const gainPct = totalInvested > 0 ? (totalGain / totalInvested * 100) : 0;

    const statsHtml = `
        <div class="stat-card">
            <div class="stat-label">Portfolio Value</div>
            <div class="stat-value">${formatCurrency(currentValue)}</div>
            <div class="stat-change ${totalGain >= 0 ? 'positive' : 'negative'}">
                ${totalGain >= 0 ? '▲' : '▼'} ${formatCurrency(Math.abs(totalGain))}
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-label">Total Invested</div>
            <div class="stat-value">${formatCurrency(totalInvested)}</div>
            <div class="stat-change" style="color: var(--text-muted);">${holdings.length} positions</div>
        </div>
        <div class="stat-card">
            <div class="stat-label">Overall Return</div>
            <div class="stat-value ${gainPct >= 0 ? 'text-success' : 'text-danger'}">${gainPct >= 0 ? '+' : ''}${gainPct.toFixed(2)}%</div>
            <div class="stat-change ${gainPct >= 0 ? 'positive' : 'negative'}">
                ${gainPct >= 0 ? 'Profit' : 'Loss'}
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-label">Cash Balance</div>
            <div class="stat-value">${formatCurrency(sum.cash_balance || 0)}</div>
            <div class="stat-change" style="color: var(--text-muted);">Available</div>
        </div>
    `;
    document.getElementById('dashboard-stats').innerHTML = statsHtml;

    const topHoldings = [...holdings]
        .sort((a, b) => parseFloat(b.market_value || 0) - parseFloat(a.market_value || 0))
        .slice(0, 5);

    const holdingsHtml = topHoldings.length > 0
        ? topHoldings.map(h => {
            const gain = parseFloat(h.unrealized_gain || 0);
            const pct = parseFloat(h.gain_pct || 0);
            return `
                <div class="holding-item">
                    <div class="holding-info">
                        <span class="holding-ticker">${h.ticker_symbol}</span>
                        <span class="holding-name">${h.company_name || h.sector || ''}</span>
                    </div>
                    <div class="holding-values">
                        <span class="holding-value">${formatCurrency(h.market_value)}</span>
                        <span class="holding-change ${gain >= 0 ? 'positive' : 'negative'}">
                            ${gain >= 0 ? '+' : ''}${formatCurrency(gain)} (${pct >= 0 ? '+' : ''}${pct.toFixed(1)}%)
                        </span>
                    </div>
                </div>
            `;
        }).join('')
        : '<div class="empty-state"><div class="empty-state-icon">📊</div><div class="empty-state-text">No holdings yet. Start trading!</div></div>';

    document.getElementById('top-holdings-list').innerHTML = holdingsHtml;

    drawAllocationChart(holdings);
}

// ---------------------------------------------------------------------------
// Portfolio
// ---------------------------------------------------------------------------
async function loadPortfolio() {
    const data = await apiFetch(`/portfolio/${currentUserId}`);
    const tbody = document.getElementById('portfolio-tbody');

    if (!data || data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="9" class="empty-state"><div class="empty-state-icon">📂</div><div class="empty-state-text">No holdings found</div></td></tr>';
        return;
    }

    tbody.innerHTML = data.map(row => {
        const gain = parseFloat(row.unrealized_gain || 0);
        const pct = parseFloat(row.gain_pct || 0);
        return `
            <tr>
                <td><span class="mono" style="font-weight:600;">${row.ticker_symbol}</span></td>
                <td>${row.company_name}</td>
                <td><span class="text-muted">${row.sector}</span></td>
                <td class="mono">${row.quantity}</td>
                <td class="mono">${formatCurrency(row.avg_buy_price)}</td>
                <td class="mono">${formatCurrency(row.current_price)}</td>
                <td class="mono" style="font-weight:600;">${formatCurrency(row.market_value)}</td>
                <td class="mono ${gain >= 0 ? 'text-success' : 'text-danger'}" style="font-weight:600;">
                    ${gain >= 0 ? '+' : ''}${formatCurrency(gain)}
                </td>
                <td class="mono ${pct >= 0 ? 'text-success' : 'text-danger'}">
                    ${pct >= 0 ? '+' : ''}${pct.toFixed(2)}%
                </td>
            </tr>
        `;
    }).join('');
}

// ---------------------------------------------------------------------------
// Trade Section
// ---------------------------------------------------------------------------
async function loadTradeSection() {
    const stocks = await apiFetch('/stocks');
    stocksCache = stocks || [];

    const select = document.getElementById('trade-ticker');
    select.innerHTML = stocksCache.map(s =>
        `<option value="${s.ticker_symbol}">${s.ticker_symbol} — ${s.company_name} (₹${parseFloat(s.current_price).toFixed(2)})</option>`
    ).join('');

    const tbody = document.getElementById('stocks-tbody');
    tbody.innerHTML = stocksCache.map(s => `
        <tr>
            <td><span class="mono" style="font-weight:600;">${s.ticker_symbol}</span></td>
            <td>${s.company_name}</td>
            <td><span class="text-muted">${s.sector}</span></td>
            <td class="mono" style="font-weight:600;">${formatCurrency(s.current_price)}</td>
            <td class="mono text-muted">${formatCurrency(s.day_low)} – ${formatCurrency(s.day_high)}</td>
            <td class="mono">${s.pe_ratio ? parseFloat(s.pe_ratio).toFixed(1) : '—'}</td>
        </tr>
    `).join('');

    updateTradePreview();
}

function initTradeForm() {
    document.getElementById('toggle-buy').addEventListener('click', () => {
        document.getElementById('trade-type').value = 'BUY';
        document.getElementById('toggle-buy').classList.add('active');
        document.getElementById('toggle-sell').classList.remove('active');
        document.getElementById('trade-submit-btn').textContent = 'Execute BUY Order';
    });

    document.getElementById('toggle-sell').addEventListener('click', () => {
        document.getElementById('trade-type').value = 'SELL';
        document.getElementById('toggle-sell').classList.add('active');
        document.getElementById('toggle-buy').classList.remove('active');
        document.getElementById('trade-submit-btn').textContent = 'Execute SELL Order';
    });

    document.getElementById('trade-ticker')?.addEventListener('change', updateTradePreview);
    document.getElementById('trade-quantity')?.addEventListener('input', updateTradePreview);
}

function updateTradePreview() {
    const ticker = document.getElementById('trade-ticker')?.value;
    const qty = parseInt(document.getElementById('trade-quantity')?.value) || 0;
    const stock = stocksCache.find(s => s.ticker_symbol === ticker);

    if (stock) {
        const price = parseFloat(stock.current_price);
        document.getElementById('preview-price').textContent = formatCurrency(price);
        document.getElementById('preview-total').textContent = formatCurrency(price * qty);
    }
}

async function executeTrade(e) {
    e.preventDefault();

    const body = {
        userId: currentUserId,
        ticker: document.getElementById('trade-ticker').value,
        type: document.getElementById('trade-type').value,
        quantity: parseInt(document.getElementById('trade-quantity').value),
    };

    const resultDiv = document.getElementById('trade-result');

    try {
        const result = await apiPost('/portfolio/trade', body);
        resultDiv.className = 'trade-result success';
        resultDiv.innerHTML = `
            ✅ <strong>${result.trade_type}</strong> ${result.shares} shares of <strong>${result.ticker}</strong>
            at ${formatCurrency(result.price_per_share)} — Total: ${formatCurrency(result.total_value)}<br>
            New balance: ${formatCurrency(result.new_balance)}
        `;
        updateHeaderBalance(result.new_balance);
        showToast(`${result.trade_type} order executed for ${result.ticker}`, 'success');

        setTimeout(() => {
            loadSectionData(currentSection);
        }, 500);
    } catch (err) {
        resultDiv.className = 'trade-result error';
        resultDiv.innerHTML = `❌ Trade failed: ${err.message}`;
        showToast('Trade failed', 'error');
    }
}

// ---------------------------------------------------------------------------
// Analytics
// ---------------------------------------------------------------------------
async function loadAnalytics() {
    const [investmentData, pnlResult] = await Promise.all([
        apiFetch(`/analytics/investment/${currentUserId}`),
        apiFetch(`/analytics/pnl/${currentUserId}`),
    ]);

    pnlData = pnlResult;

    const metrics = investmentData?.metrics || {};
    const metricsHtml = `
        <div class="metrics-grid">
            <div class="metric-item">
                <div class="metric-label">Total Invested</div>
                <div class="metric-value">${formatCurrency(metrics.total_cost_basis)}</div>
            </div>
            <div class="metric-item">
                <div class="metric-label">Market Value</div>
                <div class="metric-value">${formatCurrency(metrics.total_market_value)}</div>
            </div>
            <div class="metric-item">
                <div class="metric-label">Overall Return</div>
                <div class="metric-value ${parseFloat(metrics.overall_return_pct) >= 0 ? 'text-success' : 'text-danger'}">
                    ${parseFloat(metrics.overall_return_pct || 0) >= 0 ? '+' : ''}${parseFloat(metrics.overall_return_pct || 0).toFixed(2)}%
                </div>
            </div>
            <div class="metric-item">
                <div class="metric-label">Diversification</div>
                <div class="metric-value" style="font-size:0.85rem;">${metrics.diversification_rating || 'N/A'}</div>
            </div>
            <div class="metric-item">
                <div class="metric-label">Positions</div>
                <div class="metric-value">${metrics.total_positions || 0}</div>
            </div>
            <div class="metric-item">
                <div class="metric-label">Avg P/E Ratio</div>
                <div class="metric-value">${parseFloat(metrics.weighted_avg_pe || 0).toFixed(1)}</div>
            </div>
        </div>
    `;
    document.getElementById('analytics-metrics').innerHTML = metricsHtml;

    const sectors = investmentData?.sectors || [];
    drawSectorChart(sectors);

    renderPnlTable();
}

function initPnlTabs() {
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            pnlActiveTab = btn.dataset.tab;
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            renderPnlTable();
        });
    });
}

function renderPnlTable() {
    if (!pnlData) return;

    const thead = document.getElementById('pnl-thead');
    const tbody = document.getElementById('pnl-tbody');
    const totals = document.getElementById('pnl-totals');

    if (pnlActiveTab === 'unrealized') {
        thead.innerHTML = `<tr>
            <th>Ticker</th><th>Shares</th><th>Avg Cost</th><th>Current</th><th>P&L</th><th>Return %</th>
        </tr>`;
        tbody.innerHTML = (pnlData.unrealized || []).map(r => {
            const pnl = parseFloat(r.unrealized_pnl || 0);
            const pct = parseFloat(r.gain_pct || 0);
            return `<tr>
                <td class="mono" style="font-weight:600;">${r.ticker_symbol}</td>
                <td class="mono">${r.shares_held}</td>
                <td class="mono">${formatCurrency(r.avg_cost)}</td>
                <td class="mono">${formatCurrency(r.current_price)}</td>
                <td class="mono ${pnl >= 0 ? 'text-success' : 'text-danger'}" style="font-weight:600;">
                    ${pnl >= 0 ? '+' : ''}${formatCurrency(pnl)}
                </td>
                <td class="mono ${pct >= 0 ? 'text-success' : 'text-danger'}">
                    ${pct >= 0 ? '+' : ''}${pct.toFixed(2)}%
                </td>
            </tr>`;
        }).join('') || '<tr><td colspan="6" class="empty-state"><div class="empty-state-text">No unrealized P&L data</div></td></tr>';
    } else {
        thead.innerHTML = `<tr>
            <th>Ticker</th><th>Shares Sold</th><th>Sell Price</th><th>Avg Cost</th><th>Realized P&L</th><th>Date</th>
        </tr>`;
        tbody.innerHTML = (pnlData.realized || []).map(r => {
            const pnl = parseFloat(r.realized_pnl || 0);
            return `<tr>
                <td class="mono" style="font-weight:600;">${r.ticker_symbol}</td>
                <td class="mono">${r.shares_sold}</td>
                <td class="mono">${formatCurrency(r.sell_price)}</td>
                <td class="mono">${formatCurrency(r.avg_cost)}</td>
                <td class="mono ${pnl >= 0 ? 'text-success' : 'text-danger'}" style="font-weight:600;">
                    ${pnl >= 0 ? '+' : ''}${formatCurrency(pnl)}
                </td>
                <td class="mono text-muted">${formatDate(r.transaction_date)}</td>
            </tr>`;
        }).join('') || '<tr><td colspan="6" class="empty-state"><div class="empty-state-text">No realized P&L data</div></td></tr>';
    }

    const t = pnlData.totals || {};
    const realized = parseFloat(t.total_realized_pnl || 0);
    const unrealized = parseFloat(t.total_unrealized_pnl || 0);
    totals.innerHTML = `
        <div class="pnl-total-item">
            <span class="pnl-total-label">Total Realized P&L</span>
            <span class="pnl-total-value ${realized >= 0 ? 'text-success' : 'text-danger'}">
                ${realized >= 0 ? '+' : ''}${formatCurrency(realized)}
            </span>
        </div>
        <div class="pnl-total-item">
            <span class="pnl-total-label">Total Unrealized P&L</span>
            <span class="pnl-total-value ${unrealized >= 0 ? 'text-success' : 'text-danger'}">
                ${unrealized >= 0 ? '+' : ''}${formatCurrency(unrealized)}
            </span>
        </div>
        <div class="pnl-total-item">
            <span class="pnl-total-label">Combined P&L</span>
            <span class="pnl-total-value ${(realized + unrealized) >= 0 ? 'text-success' : 'text-danger'}">
                ${(realized + unrealized) >= 0 ? '+' : ''}${formatCurrency(realized + unrealized)}
            </span>
        </div>
    `;
}

// ---------------------------------------------------------------------------
// Transactions
// ---------------------------------------------------------------------------
async function loadTransactions() {
    const data = await apiFetch(`/transactions/${currentUserId}`);
    const tbody = document.getElementById('txn-tbody');

    if (!data || data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" class="empty-state"><div class="empty-state-text">No transactions yet</div></td></tr>';
        return;
    }

    tbody.innerHTML = data.map(t => `
        <tr>
            <td class="mono text-muted">${formatDate(t.transaction_date)}</td>
            <td><span class="mono" style="font-weight:600;">${t.ticker_symbol}</span></td>
            <td>${t.company_name}</td>
            <td><span class="badge ${t.transaction_type === 'BUY' ? 'badge-buy' : 'badge-sell'}">${t.transaction_type}</span></td>
            <td class="mono">${t.quantity}</td>
            <td class="mono">${formatCurrency(t.price_per_unit)}</td>
            <td class="mono" style="font-weight:600;">${formatCurrency(t.total_amount)}</td>
        </tr>
    `).join('');
}

// ---------------------------------------------------------------------------
// Watchlist
// ---------------------------------------------------------------------------
async function loadWatchlist() {
    const data = await apiFetch(`/watchlist/${currentUserId}`);
    const tbody = document.getElementById('watchlist-tbody');

    if (!data || data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" class="empty-state"><div class="empty-state-text">Watchlist is empty</div></td></tr>';
        return;
    }

    tbody.innerHTML = data.map(w => `
        <tr>
            <td><span class="mono" style="font-weight:600;">${w.ticker_symbol}</span></td>
            <td>${w.company_name}</td>
            <td class="text-muted">${w.sector}</td>
            <td class="mono" style="font-weight:600;">${formatCurrency(w.current_price)}</td>
            <td class="mono text-muted">${formatCurrency(w.day_low)} – ${formatCurrency(w.day_high)}</td>
            <td class="mono ${w.alert_price ? (parseFloat(w.current_price) >= parseFloat(w.alert_price) ? 'text-success' : 'text-danger') : ''}">${w.alert_price ? formatCurrency(w.alert_price) : '—'}</td>
            <td class="mono">${w.pe_ratio ? parseFloat(w.pe_ratio).toFixed(1) : '—'}</td>
            <td class="mono text-muted">${formatDate(w.added_at)}</td>
        </tr>
    `).join('');
}

// ---------------------------------------------------------------------------
// Canvas Charts
// ---------------------------------------------------------------------------
const CHART_COLORS = [
    '#2563eb', '#16a34a', '#d97706', '#dc2626', '#7c3aed',
    '#0891b2', '#e11d48', '#65a30d', '#0d9488', '#c2410c'
];

function drawDonutChart(canvasId, segments, centerText) {
    const canvas = document.getElementById(canvasId);
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    const dpr = window.devicePixelRatio || 1;
    const width = canvas.clientWidth || 340;
    const height = canvas.clientHeight || 340;

    canvas.width = width * dpr;
    canvas.height = height * dpr;
    ctx.scale(dpr, dpr);

    const cx = width / 2;
    const cy = height / 2;
    const radius = Math.min(cx, cy) - 30;
    const innerRadius = radius * 0.6;

    ctx.clearRect(0, 0, width, height);

    if (segments.length === 0) {
        ctx.beginPath();
        ctx.arc(cx, cy, radius, 0, Math.PI * 2);
        ctx.arc(cx, cy, innerRadius, 0, Math.PI * 2, true);
        ctx.fillStyle = '#e8e9ed';
        ctx.fill();
        ctx.font = '500 13px Inter';
        ctx.fillStyle = '#8b919e';
        ctx.textAlign = 'center';
        ctx.fillText('No data', cx, cy);
        return;
    }

    const total = segments.reduce((a, s) => a + s.value, 0);
    let startAngle = -Math.PI / 2;

    segments.forEach((seg, i) => {
        const sliceAngle = (seg.value / total) * Math.PI * 2;
        const endAngle = startAngle + sliceAngle;

        ctx.beginPath();
        ctx.arc(cx, cy, radius, startAngle, endAngle);
        ctx.arc(cx, cy, innerRadius, endAngle, startAngle, true);
        ctx.closePath();
        ctx.fillStyle = CHART_COLORS[i % CHART_COLORS.length];
        ctx.fill();

        // Gap between slices
        ctx.beginPath();
        ctx.arc(cx, cy, radius, endAngle - 0.01, endAngle + 0.01);
        ctx.arc(cx, cy, innerRadius, endAngle + 0.01, endAngle - 0.01, true);
        ctx.fillStyle = '#ffffff';
        ctx.fill();

        // Label
        if (sliceAngle > 0.2) {
            const midAngle = startAngle + sliceAngle / 2;
            const labelR = radius + 18;
            const lx = cx + Math.cos(midAngle) * labelR;
            const ly = cy + Math.sin(midAngle) * labelR;

            ctx.font = '500 10px Inter';
            ctx.fillStyle = '#5a6170';
            ctx.textAlign = midAngle > Math.PI / 2 && midAngle < Math.PI * 1.5 ? 'right' : 'left';
            ctx.textBaseline = 'middle';
            ctx.fillText(`${seg.label} ${(seg.value / total * 100).toFixed(0)}%`, lx, ly);
        }

        startAngle = endAngle;
    });

    // Center text
    if (centerText) {
        ctx.font = '700 16px "JetBrains Mono"';
        ctx.fillStyle = '#1a1d24';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(centerText.top || '', cx, cy - 8);
        ctx.font = '400 10px Inter';
        ctx.fillStyle = '#8b919e';
        ctx.fillText(centerText.bottom || '', cx, cy + 10);
    }

    // Legend
    const legendY = cy + radius + 35;
    const legendStartX = cx - (Math.min(segments.length, 6) * 75) / 2;

    segments.forEach((seg, i) => {
        if (i >= 6) return;
        const x = legendStartX + i * 75;
        ctx.fillStyle = CHART_COLORS[i % CHART_COLORS.length];
        ctx.beginPath();
        ctx.roundRect(x, legendY, 8, 8, 2);
        ctx.fill();
        ctx.font = '400 9px Inter';
        ctx.fillStyle = '#5a6170';
        ctx.textAlign = 'left';
        ctx.fillText(seg.label.substring(0, 8), x + 12, legendY + 7);
    });
}

function drawAllocationChart(holdings) {
    if (!holdings || holdings.length === 0) {
        drawDonutChart('allocation-chart', [], null);
        return;
    }

    const segments = holdings.map(h => ({
        label: h.ticker_symbol,
        value: parseFloat(h.market_value || 0),
    }));

    const total = segments.reduce((a, s) => a + s.value, 0);
    drawDonutChart('allocation-chart', segments, {
        top: formatCurrency(total),
        bottom: 'Total Value'
    });
}

function drawSectorChart(sectors) {
    if (!sectors || sectors.length === 0) {
        drawDonutChart('sector-chart', [], null);
        return;
    }

    const segments = sectors.map(s => ({
        label: s.sector,
        value: parseFloat(s.current_value || s.sector_value || 0),
    }));

    drawDonutChart('sector-chart', segments, {
        top: sectors.length.toString(),
        bottom: 'Sectors'
    });
}

// ---------------------------------------------------------------------------
// Formatting Helpers — INR
// ---------------------------------------------------------------------------
function formatCurrency(value) {
    const n = parseFloat(value);
    if (isNaN(n)) return '₹0.00';
    return '₹' + n.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function formatDate(dateStr) {
    if (!dateStr) return '—';
    const d = new Date(dateStr);
    return d.toLocaleDateString('en-IN', { year: 'numeric', month: 'short', day: 'numeric' });
}

// ---------------------------------------------------------------------------
// Toast
// ---------------------------------------------------------------------------
function showToast(message, type = 'info') {
    const container = document.getElementById('toast-container');
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    container.appendChild(toast);

    setTimeout(() => {
        toast.remove();
    }, 3500);
}
