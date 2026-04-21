document.addEventListener('DOMContentLoaded', () => {
    const uiTotalValue = document.getElementById('ui-total-value');
    const uiTotalGain = document.getElementById('ui-total-gain');
    const uiPortfolioBody = document.getElementById('ui-portfolio-body');
    const uiWatchlist = document.getElementById('ui-watchlist');
    const uiHistory = document.getElementById('ui-history');
    const uiTradeForm = document.getElementById('ui-trade-form');
    const userSelector = document.getElementById('user-selector');
    const btnNewUser = document.getElementById('btn-new-user');
    const userModal = document.getElementById('user-modal');
    const closeModal = document.querySelector('.close-modal');
    const createUserForm = document.getElementById('create-user-form');
    const currentUserAvatar = document.getElementById('current-user-avatar');

    let currentUserId = parseInt(localStorage.getItem('currentUserId')) || 1;

    const formatCurrency = (val) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(val);
    const formatPercent = (val) => (val > 0 ? '+' : '') + val.toFixed(2) + '%';

    const fetchUsers = async () => {
        try {
            const res = await fetch('/api/users');
            if(!res.ok) return;
            const users = await res.json();
            
            let html = '';
            users.forEach(user => {
                html += `<option value="${user.userId}" ${user.userId === currentUserId ? 'selected' : ''}>${user.username}</option>`;
                if (user.userId === currentUserId) {
                    currentUserAvatar.innerText = user.username.charAt(0).toUpperCase();
                }
            });
            if (userSelector) userSelector.innerHTML = html;
            
            // If current user is not in the list (e.g. database reset), default to first user
            if (users.length > 0 && !users.find(u => u.userId === currentUserId)) {
                currentUserId = users[0].userId;
                localStorage.setItem('currentUserId', currentUserId);
                refreshAllData();
            }
        } catch (e) { console.error('Failed to fetch users', e); }
    };

    const refreshAllData = () => {
        fetchPortfolio();
        fetchMarket();
        fetchHistory();
        if (document.getElementById('view-analytics').classList.contains('active') || !document.getElementById('view-analytics').classList.contains('hidden')) {
            fetchAnalytics();
        }
    };

    const fetchPortfolio = async () => {
        try {
            const res = await fetch(`/api/portfolio?userId=${currentUserId}`);
            if(!res.ok) return;
            const data = await res.json();
            
            let totalValue = 0;
            let totalInvestment = 0;
            let tbodyHtml = '';

            data.forEach(item => {
                totalValue += item.currentValue;
                totalInvestment += item.totalInvestment;
                
                const percentChange = ((item.currentValue - item.totalInvestment) / item.totalInvestment) * 100 || 0;
                const badgeClass = percentChange >= 0 ? 'pos-bg' : 'neg-bg';
                
                let currentPrice = item.quantity > 0 ? item.currentValue / item.quantity : 0;

                tbodyHtml += `
                    <tr>
                        <td><span class="badge ticker-badge">${item.stockSymbol}</span></td>
                        <td>${item.stockSymbol} Equity</td>
                        <td>${item.quantity}</td>
                        <td>${formatCurrency(item.avgBuyPrice)}</td>
                        <td>${formatCurrency(currentPrice)}</td>
                        <td><span class="badge ${badgeClass}">${formatPercent(percentChange)}</span></td>
                    </tr>
                `;
            });

            if (uiPortfolioBody) uiPortfolioBody.innerHTML = tbodyHtml;
            
            if (uiTotalValue) uiTotalValue.innerText = formatCurrency(totalValue);
            
            const totalGain = totalValue - totalInvestment;
            const totalGainPercent = (totalGain / totalInvestment) * 100 || 0;
            if (uiTotalGain) {
                uiTotalGain.innerHTML = `${totalGain >= 0 ? '+' : ''} ${formatCurrency(totalGain)} <small>(${formatPercent(totalGainPercent)})</small>`;
                uiTotalGain.className = `gain-value ${totalGain >= 0 ? 'pos' : 'neg'}`;
            }

        } catch (e) { console.error('Failed to fetch portfolio', e); }
    };

    const fetchMarket = async () => {
        try {
            const res = await fetch('/api/market');
            if(!res.ok) return;
            const data = await res.json();
            
            let watchlistHtml = '';
            let dropdownHtml = '<option value="" disabled selected>Select an Indian Stock...</option>';
            
            data.slice(0, 6).forEach(stock => {
                watchlistHtml += `
                    <li>
                        <span class="ticker">${stock.stockSymbol}</span>
                        <span class="trend pos">${formatCurrency(stock.currentPrice)}</span>
                    </li>
                `;
            });
            
            data.forEach(stock => {
                dropdownHtml += `<option value="${stock.stockSymbol}">${stock.stockSymbol} - ${formatCurrency(stock.currentPrice)}</option>`;
            });

            if (uiWatchlist) uiWatchlist.innerHTML = watchlistHtml;
            
            const tickerSelect = document.getElementById('trade-ticker');
            if (tickerSelect) {
                const currentVal = tickerSelect.value;
                tickerSelect.innerHTML = dropdownHtml;
                if (currentVal) tickerSelect.value = currentVal;
            }
        } catch (e) { console.error('Failed to fetch market', e); }
    };

    const fetchHistory = async () => {
        try {
            const res = await fetch(`/api/history?userId=${currentUserId}`);
            if(!res.ok) return;
            const data = await res.json();
            
            let html = '';
            data.slice(0, 5).forEach(t => {
                const isBuy = t.transactionType === 'BUY';
                html += `
                    <li class="history-item ${isBuy ? 'buy-action' : 'sell-action'}">
                        <div class="hist-icon">${isBuy ? '↓' : '↑'}</div>
                        <div class="hist-details">
                            <strong>${isBuy ? 'Bought' : 'Sold'} ${t.stockSymbol}</strong>
                            <span>${new Date(t.transactionDate).toLocaleDateString()} - ${t.quantity} Shares</span>
                        </div>
                        <div class="hist-price">${isBuy ? '-' : '+'}${formatCurrency(t.pricePerShare * t.quantity)}</div>
                    </li>
                `;
            });
            if (uiHistory) uiHistory.innerHTML = html;
        } catch (e) { console.error('Failed to fetch history', e); }
    };

    if (uiTradeForm) {
        uiTradeForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const ticker = document.getElementById('trade-ticker').value;
            const qty = parseInt(document.getElementById('trade-qty').value) || 0;
            const type = document.getElementById('trade-type').value;

            if (qty <= 0) {
                alert('Quantity must be greater than 0');
                return;
            }

            try {
                const res = await fetch(`/api/trade?userId=${currentUserId}`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ ticker, qty, type })
                });
                const ans = await res.json();
                
                if(res.ok && ans.success) {
                    document.getElementById('trade-ticker').value = '';
                    document.getElementById('trade-qty').value = '';
                    fetchPortfolio();
                    fetchHistory();
                } else {
                    alert('Database insertion failed! Check Java Console or Triggers. Error: ' + (ans.error || 'Unknown SQL failure.'));
                }
            } catch (e) {
                console.error(e);
                alert('Network or Server Error: ' + e);
            }
        });
    }

    document.querySelectorAll('.nav-item').forEach(link => {
        link.addEventListener('click', (e) => {
            const targetId = link.getAttribute('data-target');
            if(!targetId) return;
            e.preventDefault();

            document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
            link.classList.add('active');

            document.querySelectorAll('.view-section').forEach(sec => sec.classList.add('hidden'));
            document.getElementById(targetId).classList.remove('hidden');

            if(targetId === 'view-analytics') {
                fetchAnalytics();
            }
        });
    });

    const fetchAnalytics = async () => {
        try {
            const res = await fetch(`/api/analytics?userId=${currentUserId}`);
            if(!res.ok) return;
            const data = await res.json();
            
            const tfObj = document.getElementById('ui-top-performer');
            const worstObj = document.getElementById('ui-worst-performer');
            const peObj = document.getElementById('ui-avg-pe');
            const concObj = document.getElementById('ui-concentration-risk');
            const roiObj = document.getElementById('ui-portfolio-roi');
            const turnObj = document.getElementById('ui-turnover-ratio');
            
            if(tfObj) tfObj.innerHTML = `${data.topPerformerSymbol} <small>(${formatCurrency(data.topPerformerProfit)})</small>`;
            if(data.worstPerformerSymbol && worstObj) {
                worstObj.innerHTML = `${data.worstPerformerSymbol} <small>(${formatCurrency(data.worstPerformerProfit)})</small>`;
            }
            if(peObj) peObj.innerText = data.avgPeRatio.toFixed(1) + 'x';
            if(concObj) concObj.innerText = data.concentrationRiskPct.toFixed(2) + '%';
            if(roiObj) {
                roiObj.innerText = (data.roiPct > 0 ? '+' : '') + data.roiPct.toFixed(2) + '%';
                roiObj.className = `gain-value ${data.roiPct >= 0 ? 'pos' : 'neg'}`;
            }
            if(turnObj) turnObj.innerText = data.turnoverRatio.toFixed(2) + 'x';
            
        } catch (e) { console.error('Failed to fetch analytics', e); }
    };

    // User Event Listeners
    if (userSelector) {
        userSelector.addEventListener('change', (e) => {
            currentUserId = parseInt(e.target.value);
            localStorage.setItem('currentUserId', currentUserId);
            const selectedText = userSelector.options[userSelector.selectedIndex].text;
            currentUserAvatar.innerText = selectedText.charAt(0).toUpperCase();
            refreshAllData();
        });
    }

    if (btnNewUser) {
        btnNewUser.addEventListener('click', () => userModal.classList.remove('hidden'));
    }

    if (closeModal) {
        closeModal.addEventListener('click', () => userModal.classList.add('hidden'));
    }

    window.addEventListener('click', (e) => {
        if (e.target === userModal) userModal.classList.add('hidden');
    });

    if (createUserForm) {
        createUserForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const username = document.getElementById('new-username').value;
            const email = document.getElementById('new-email').value;
            const phone = document.getElementById('new-phone').value;

            try {
                const res = await fetch('/api/users', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ username, email, phone })
                });
                const data = await res.json();
                if (res.ok && data.success) {
                    userModal.classList.add('hidden');
                    createUserForm.reset();
                    fetchUsers();
                } else {
                    alert('Failed to create user: ' + (data.error || 'Unknown error'));
                }
            } catch (err) {
                console.error(err);
                alert('Network error while creating user');
            }
        });
    }

    // Start live updates matching the 4 second Java Simulation
    setInterval(() => {
        fetchPortfolio();
        fetchMarket();
    }, 4000);

    // Initial load
    fetchUsers();
    fetchPortfolio();
    fetchMarket();
    fetchHistory();
});
