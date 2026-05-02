import React, { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Link, useLocation } from 'react-router-dom';
import { db } from './firebase';
import { collection, query, where, onSnapshot, doc, updateDoc, setDoc } from 'firebase/firestore';
import { LayoutDashboard, Menu, BellRing, Users } from 'lucide-react';
import './App.css';

// Dashboard Component
const Dashboard = () => {
  const [bookings, setBookings] = useState([]);
  const [users, setUsers] = useState([]);
  
  const firebaseAvailable = Boolean(import.meta.env.VITE_FIREBASE_API_KEY && import.meta.env.VITE_FIREBASE_PROJECT_ID && import.meta.env.VITE_FIREBASE_APP_ID);

  useEffect(() => {
    if (!firebaseAvailable) {
      setUsers([]);
      setBookings([]);
      return;
    }
    // Listen for users
    const unsubUsers = onSnapshot(collection(db, 'users'), (snapshot) => {
      const u = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setUsers(u);
    });

    // Listen for tomorrow's bookings
    const q = query(collection(db, 'bookings'), where('date', 'in', ['tomorrow', 'June 26, 2026']));
    const unsubBookings = onSnapshot(q, (snapshot) => {
      const b = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setBookings(b);
    });

    return () => { unsubUsers(); unsubBookings(); };
  }, []);

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-8">Dashboard</h1>
      <div className="grid grid-cols-2 gap-6 mb-8">
        <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm">
          <h3 className="text-gray-500 text-sm font-semibold mb-2">TOTAL USERS</h3>
          <p className="text-4xl font-bold">{users.length || 0}</p>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm">
          <h3 className="text-gray-500 text-sm font-semibold mb-2">BOOKINGS FOR TOMORROW</h3>
          <p className="text-4xl font-bold text-orange-500">{bookings.length || 0}</p>
        </div>
      </div>
      
      <h2 className="text-xl font-bold mb-4">Live Users</h2>
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        <table className="w-full text-left">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-4 text-sm font-semibold text-gray-500">ID</th>
              <th className="px-6 py-4 text-sm font-semibold text-gray-500">Name</th>
            </tr>
          </thead>
          <tbody>
            {users.length === 0 ? (
              <tr><td className="px-6 py-4 text-gray-500">No users found.</td></tr>
            ) : users.map(u => (
              <tr key={u.id} className="border-t border-gray-100">
                <td className="px-6 py-4 text-sm text-gray-500">{u.id}</td>
                <td className="px-6 py-4 text-sm font-semibold">{u.name || 'Student'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

// Menu Manager Component
const MenuManager = () => {
  const [menus, setMenus] = useState({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!firebaseAvailable) {
      setMenus({});
      setLoading(false);
      return;
    }
    const unsub = onSnapshot(collection(db, 'menu'), (snapshot) => {
      const data = {};
      snapshot.forEach(doc => {
        data[doc.id] = doc.data().items || [];
      });
      setMenus(data);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const handleUpdate = async (mealType, newItemsStr) => {
    if (!firebaseAvailable) {
      alert('Firebase not configured. Set VITE_FIREBASE_* env vars in admin_panel/.env.');
      return;
    }
    const itemsArray = newItemsStr.split(',').map(s => s.trim()).filter(s => s);
    try {
      await setDoc(doc(db, 'menu', mealType.toLowerCase()), { items: itemsArray });
      alert(`Updated ${mealType} menu!`);
    } catch (e) {
      alert(`Error updating ${mealType}: ` + e.message);
    }
  };

  if (loading) return <div className="p-8">Loading menus...</div>;

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-8">Menu Manager</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {['breakfast', 'lunch', 'snacks', 'dinner'].map(meal => (
          <div key={meal} className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm">
            <h2 className="text-xl font-bold mb-4 capitalize">{meal} Menu</h2>
            <textarea
              className="w-full border border-gray-200 rounded-lg p-3 text-sm mb-4 h-24 font-mono"
              defaultValue={(menus[meal] || []).join(', ')}
              id={`textarea-${meal}`}
              placeholder="E.g. Poha, Boiled Eggs"
            />
            <button
              className="w-full bg-orange-500 hover:bg-orange-600 text-white font-bold py-2 rounded-lg transition-colors"
              onClick={() => handleUpdate(meal, document.getElementById(`textarea-${meal}`).value)}
            >
              Update {meal}
            </button>
          </div>
        ))}
      </div>
    </div>
  );
};

// Notice Manager Component
const NoticeManager = () => {
  const [notice, setNotice] = useState({ message: '', active: false });

  useEffect(() => {
    if (!firebaseAvailable) {
      setNotice({ message: '', active: false });
      return;
    }
    const unsub = onSnapshot(doc(db, 'notices', 'current'), (doc) => {
      if (doc.exists()) {
        setNotice(doc.data());
      }
    });
    return () => unsub();
  }, []);

  const handleUpdate = async (e) => {
    e.preventDefault();
    if (!firebaseAvailable) {
      alert('Firebase not configured. Set VITE_FIREBASE_* env vars in admin_panel/.env.');
      return;
    }
    const newMsg = document.getElementById('noticeMsg').value;
    const active = document.getElementById('noticeActive').checked;
    await setDoc(doc(db, 'notices', 'current'), {
      message: newMsg,
      active: active,
      updatedAt: new Date()
    });
    alert('Notice updated successfully!');
  };

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-8">Notice Manager</h1>
      <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm max-w-lg">
        <form onSubmit={handleUpdate}>
          <div className="mb-4">
            <label className="block text-sm font-semibold mb-2">Notice Message</label>
            <textarea
              id="noticeMsg"
              className="w-full border border-gray-200 rounded-lg p-3 text-sm h-24"
              defaultValue={notice.message}
              placeholder="E.g. Menu update: Kheer added tonight"
              required
            />
          </div>
          <div className="mb-6 flex items-center">
            <input
              type="checkbox"
              id="noticeActive"
              className="w-5 h-5 accent-orange-500 cursor-pointer"
              defaultChecked={notice.active}
            />
            <label htmlFor="noticeActive" className="ml-3 font-medium cursor-pointer">Activate Notice on App</label>
          </div>
          <button type="submit" className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 rounded-lg transition-colors">
            Publish Notice
          </button>
        </form>
      </div>
    </div>
  );
};

const Sidebar = () => {
  const location = useLocation();
  const navItems = [
    { path: '/', label: 'Dashboard', icon: LayoutDashboard },
    { path: '/menu', label: 'Menu Manager', icon: Menu },
    { path: '/notices', label: 'Notices', icon: BellRing },
  ];

  return (
    <div className="w-64 bg-gray-900 text-white h-screen sticky top-0 flex flex-col p-4">
      <div className="mb-10 px-4 py-2 mt-4">
        <h2 className="text-2xl font-bold text-orange-500 tracking-tight">Hostel Admin</h2>
      </div>
      <nav className="flex-1 space-y-2">
        {navItems.map(item => {
          const Icon = item.icon;
          const isActive = location.pathname === item.path;
          return (
            <Link key={item.path} to={item.path}
              className={`flex items-center px-4 py-3 rounded-xl transition-all ${
                isActive ? 'bg-orange-500/10 text-orange-500 font-bold' : 'text-gray-400 hover:bg-white/5 hover:text-white'
              }`}
            >
              <Icon size={20} className="mr-3" />
              {item.label}
            </Link>
          );
        })}
      </nav>
    </div>
  );
};

export default function App() {
  return (
    <BrowserRouter>
      <div className="flex min-h-screen bg-[#FDFDFC] text-gray-800 font-sans">
        <Sidebar />
        <div className="flex-1 overflow-auto">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/menu" element={<MenuManager />} />
            <Route path="/notices" element={<NoticeManager />} />
          </Routes>
        </div>
      </div>
    </BrowserRouter>
  );
}
