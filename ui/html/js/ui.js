function showNotification(title, message, notificationType) {
    const existing = document.querySelector('.toast-notification');
    if (existing) {
        existing.remove();
    }

    const toast = document.createElement('div');
    const tone = notificationType || 'info';

    toast.className = `toast-notification toast-${tone}`;
    toast.innerHTML = `
        <div class="toast-title">${title || 'Trucking'}</div>
        <div class="toast-message">${message || ''}</div>
    `;

    toast.style.position = 'fixed';
    toast.style.top = '24px';
    toast.style.right = '24px';
    toast.style.zIndex = '9999';
    toast.style.minWidth = '240px';
    toast.style.maxWidth = '360px';
    toast.style.padding = '12px 16px';
    toast.style.borderRadius = '8px';
    toast.style.background = 'rgba(18, 18, 18, 0.95)';
    toast.style.color = '#ffffff';
    toast.style.boxShadow = '0 10px 30px rgba(0, 0, 0, 0.35)';
    toast.style.borderLeft = '4px solid #4f46e5';

    if (tone === 'success') {
        toast.style.borderLeftColor = '#22c55e';
    } else if (tone === 'warning') {
        toast.style.borderLeftColor = '#f59e0b';
    } else if (tone === 'error') {
        toast.style.borderLeftColor = '#ef4444';
    }

    document.body.appendChild(toast);

    setTimeout(() => {
        toast.remove();
    }, 4000);
}
