import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import { toast } from "sonner";
import { ArrowLeft, LogOut, Plus, Pencil, Trash2, UserCheck, Calendar, DollarSign } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

const MONTHS = [
  "January","February","March","April","May","June",
  "July","August","September","October","November","December"
];

const OwnerDashboard = ({ onLogout }) => {
  const navigate = useNavigate();
  const [staff, setStaff] = useState([]);
  const [showStaffDialog, setShowStaffDialog] = useState(false);
  const [editingStaff, setEditingStaff] = useState(null);
  const [staffForm, setStaffForm] = useState({
    name: "", role: "", phone: "", salary_type: "monthly", salary_amount: 0
  });

  // Attendance state
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth() + 1);
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());
  const [attendanceData, setAttendanceData] = useState({});
  const [attendanceStaff, setAttendanceStaff] = useState("");

  // Salary state
  const [salaryMonth, setSalaryMonth] = useState(new Date().getMonth() + 1);
  const [salaryYear, setSalaryYear] = useState(new Date().getFullYear());
  const [workingDays, setWorkingDays] = useState(26);
  const [salaryRecords, setSalaryRecords] = useState([]);

  const fetchStaff = useCallback(async () => {
    try {
      const response = await axios.get(`${API}/staff`);
      setStaff(response.data);
    } catch (error) { console.error("Error fetching staff:", error); }
  }, []);

  useEffect(() => { fetchStaff(); }, [fetchStaff]);

  // --- Staff CRUD ---
  const handleSaveStaff = async () => {
    if (!staffForm.name || !staffForm.role || !staffForm.salary_amount) {
      toast.error("Fill all required fields");
      return;
    }
    try {
      if (editingStaff) {
        await axios.put(`${API}/staff/${editingStaff.id}`, staffForm);
        toast.success("Staff updated");
      } else {
        await axios.post(`${API}/staff`, staffForm);
        toast.success("Staff added");
      }
      setShowStaffDialog(false);
      setEditingStaff(null);
      setStaffForm({ name: "", role: "", phone: "", salary_type: "monthly", salary_amount: 0 });
      fetchStaff();
    } catch (error) { toast.error("Failed to save staff"); }
  };

  const handleDeleteStaff = async (id) => {
    if (!window.confirm("Delete this staff member?")) return;
    try {
      await axios.delete(`${API}/staff/${id}`);
      toast.success("Staff deleted");
      fetchStaff();
    } catch (error) { toast.error("Failed to delete"); }
  };

  const openEditStaff = (s) => {
    setEditingStaff(s);
    setStaffForm({
      name: s.name, role: s.role, phone: s.phone,
      salary_type: s.salary_type, salary_amount: s.salary_amount
    });
    setShowStaffDialog(true);
  };

  // --- Attendance ---
  const fetchAttendance = useCallback(async () => {
    if (!attendanceStaff) return;
    try {
      const res = await axios.get(`${API}/attendance/summary/${attendanceStaff}/${selectedYear}/${selectedMonth}`);
      const map = {};
      res.data.records.forEach(r => { map[r.date] = r.status; });
      setAttendanceData(map);
    } catch (error) { console.error(error); }
  }, [attendanceStaff, selectedMonth, selectedYear]);

  useEffect(() => { fetchAttendance(); }, [fetchAttendance]);

  const markAttendance = async (day, status) => {
    const date = `${selectedYear}-${String(selectedMonth).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    const staffMember = staff.find(s => s.id === attendanceStaff);
    try {
      await axios.post(`${API}/attendance`, {
        staff_id: attendanceStaff,
        staff_name: staffMember?.name || "",
        date,
        status
      });
      fetchAttendance();
    } catch (error) { toast.error("Failed to mark attendance"); }
  };

  const getDaysInMonth = (month, year) => new Date(year, month, 0).getDate();

  // --- Salary ---
  const fetchSalaries = useCallback(async () => {
    try {
      const res = await axios.get(`${API}/salary?month=${salaryMonth}&year=${salaryYear}`);
      setSalaryRecords(res.data);
    } catch (error) { console.error(error); }
  }, [salaryMonth, salaryYear]);

  useEffect(() => { fetchSalaries(); }, [fetchSalaries]);

  const generateSalary = async (staffId) => {
    try {
      await axios.post(`${API}/salary/generate`, {
        staff_id: staffId,
        month: salaryMonth,
        year: salaryYear,
        total_working_days: workingDays
      });
      toast.success("Salary generated");
      fetchSalaries();
    } catch (error) { toast.error("Failed to generate salary"); }
  };

  const generateAllSalaries = async () => {
    for (const s of staff) {
      await generateSalary(s.id);
    }
    toast.success("All salaries generated");
  };

  const daysCount = getDaysInMonth(selectedMonth, selectedYear);

  return (
    <div className="min-h-screen bg-[#F9F8F6]">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-white border-b border-[#E0DBD3] shadow-[0_4px_12px_rgba(42,47,43,0.04)]">
        <div className="flex items-center justify-between p-4">
          <button onClick={() => navigate("/")} className="flex items-center gap-2 text-[#5A615C] hover:text-[#2A2F2B]" data-testid="back-btn">
            <ArrowLeft className="w-5 h-5" /><span className="text-sm font-semibold">Back</span>
          </button>
          <h1 className="text-xl md:text-2xl font-medium text-[#2A2F2B] tracking-tight">Owner Panel</h1>
          <button onClick={onLogout} className="flex items-center gap-2 text-[#B24040] hover:text-[#8a2e2e]" data-testid="logout-btn">
            <LogOut className="w-5 h-5" /><span className="text-sm font-semibold">Lock</span>
          </button>
        </div>
      </div>

      <div className="p-6">
        <Tabs defaultValue="staff" className="w-full">
          <TabsList className="grid w-full max-w-lg grid-cols-3 mb-6" data-testid="owner-tabs">
            <TabsTrigger value="staff" data-testid="staff-tab">
              <UserCheck className="w-4 h-4 mr-2" />Staff
            </TabsTrigger>
            <TabsTrigger value="attendance" data-testid="attendance-tab">
              <Calendar className="w-4 h-4 mr-2" />Attendance
            </TabsTrigger>
            <TabsTrigger value="salary" data-testid="salary-tab">
              <DollarSign className="w-4 h-4 mr-2" />Salary
            </TabsTrigger>
          </TabsList>

          {/* ============ STAFF TAB ============ */}
          <TabsContent value="staff" data-testid="staff-section">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-2xl md:text-3xl tracking-tight font-medium text-[#2A2F2B]">Staff Management</h2>
              <Button onClick={() => { setEditingStaff(null); setStaffForm({ name: "", role: "", phone: "", salary_type: "monthly", salary_amount: 0 }); setShowStaffDialog(true); }}
                data-testid="add-staff-btn" className="min-h-[48px] bg-[#C25934] hover:bg-[#A84C2B] text-white rounded-md font-semibold">
                <Plus className="w-4 h-4 mr-2" />Add Staff
              </Button>
            </div>

            <div className="bg-white border border-[#E0DBD3] rounded-xl overflow-hidden shadow-[0_4px_12px_rgba(42,47,43,0.04)]">
              <table className="w-full">
                <thead className="bg-[#F2EFE9]">
                  <tr>
                    <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">Name</th>
                    <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">Role</th>
                    <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">Phone</th>
                    <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">Salary Type</th>
                    <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">Amount</th>
                    <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {staff.length === 0 ? (
                    <tr><td colSpan="6" className="text-center py-12 text-[#5A615C]">No staff added yet</td></tr>
                  ) : staff.map(s => (
                    <tr key={s.id} className="border-t border-[#E0DBD3]" data-testid={`staff-row-${s.id}`}>
                      <td className="p-4 font-semibold text-[#2A2F2B]">{s.name}</td>
                      <td className="p-4 text-[#5A615C]">{s.role}</td>
                      <td className="p-4 text-[#5A615C]">{s.phone}</td>
                      <td className="p-4">
                        <span className={`px-3 py-1 rounded-md text-xs font-semibold uppercase tracking-[0.15em] ${s.salary_type === "monthly" ? "bg-[#E9F0EC] text-[#4A6B56]" : "bg-[#FDF4E6] text-[#D99C3D]"}`}>
                          {s.salary_type}
                        </span>
                      </td>
                      <td className="p-4 font-semibold text-[#C25934]">₹{s.salary_amount.toLocaleString()}</td>
                      <td className="p-4">
                        <div className="flex gap-2">
                          <button onClick={() => openEditStaff(s)} data-testid={`edit-staff-${s.id}`} className="p-2 text-[#5A615C] hover:bg-[#F2EFE9] rounded-md"><Pencil className="w-4 h-4" /></button>
                          <button onClick={() => handleDeleteStaff(s.id)} data-testid={`delete-staff-${s.id}`} className="p-2 text-[#B24040] hover:bg-[#FAEDED] rounded-md"><Trash2 className="w-4 h-4" /></button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </TabsContent>

          {/* ============ ATTENDANCE TAB ============ */}
          <TabsContent value="attendance" data-testid="attendance-section">
            <h2 className="text-2xl md:text-3xl tracking-tight font-medium text-[#2A2F2B] mb-6">Mark Attendance</h2>

            <div className="flex flex-wrap gap-4 mb-6">
              <Select value={attendanceStaff} onValueChange={setAttendanceStaff}>
                <SelectTrigger data-testid="attendance-staff-select" className="w-[200px] bg-[#F2EFE9] border-[#E0DBD3]">
                  <SelectValue placeholder="Select Staff" />
                </SelectTrigger>
                <SelectContent>
                  {staff.map(s => (
                    <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>

              <Select value={String(selectedMonth)} onValueChange={(v) => setSelectedMonth(parseInt(v))}>
                <SelectTrigger data-testid="attendance-month-select" className="w-[160px] bg-[#F2EFE9] border-[#E0DBD3]">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {MONTHS.map((m, i) => (
                    <SelectItem key={i} value={String(i + 1)}>{m}</SelectItem>
                  ))}
                </SelectContent>
              </Select>

              <Select value={String(selectedYear)} onValueChange={(v) => setSelectedYear(parseInt(v))}>
                <SelectTrigger data-testid="attendance-year-select" className="w-[120px] bg-[#F2EFE9] border-[#E0DBD3]">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {[2025, 2026, 2027].map(y => (
                    <SelectItem key={y} value={String(y)}>{y}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {!attendanceStaff ? (
              <div className="bg-white border border-[#E0DBD3] rounded-xl p-12 text-center" data-testid="no-staff-selected">
                <Calendar className="w-16 h-16 text-[#E0DBD3] mx-auto mb-4" />
                <p className="text-[#5A615C]">Select a staff member to mark attendance</p>
              </div>
            ) : (
              <div className="bg-white border border-[#E0DBD3] rounded-xl p-6 shadow-[0_4px_12px_rgba(42,47,43,0.04)]">
                <div className="mb-4">
                  <h3 className="text-lg font-semibold text-[#2A2F2B]">
                    {staff.find(s => s.id === attendanceStaff)?.name} - {MONTHS[selectedMonth - 1]} {selectedYear}
                  </h3>
                </div>
                <div className="grid grid-cols-7 gap-2">
                  {["Sun","Mon","Tue","Wed","Thu","Fri","Sat"].map(d => (
                    <div key={d} className="text-center text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C] py-2">{d}</div>
                  ))}
                  {/* Empty cells for first day offset */}
                  {Array.from({ length: new Date(selectedYear, selectedMonth - 1, 1).getDay() }, (_, i) => (
                    <div key={`empty-${i}`} />
                  ))}
                  {Array.from({ length: daysCount }, (_, i) => {
                    const day = i + 1;
                    const dateStr = `${selectedYear}-${String(selectedMonth).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
                    const status = attendanceData[dateStr];

                    return (
                      <div key={day} data-testid={`day-${day}`} className="border border-[#E0DBD3] rounded-lg p-2 text-center">
                        <div className="text-sm font-semibold text-[#2A2F2B] mb-2">{day}</div>
                        <div className="flex flex-col gap-1">
                          <button
                            onClick={() => markAttendance(day, "present")}
                            data-testid={`mark-present-${day}`}
                            className={`text-xs px-1 py-1 rounded transition-colors ${status === "present" ? "bg-[#4A6B56] text-white" : "bg-[#F2EFE9] text-[#5A615C] hover:bg-[#E9F0EC]"}`}
                          >P</button>
                          <button
                            onClick={() => markAttendance(day, "half_day")}
                            data-testid={`mark-halfday-${day}`}
                            className={`text-xs px-1 py-1 rounded transition-colors ${status === "half_day" ? "bg-[#D99C3D] text-white" : "bg-[#F2EFE9] text-[#5A615C] hover:bg-[#FDF4E6]"}`}
                          >H</button>
                          <button
                            onClick={() => markAttendance(day, "absent")}
                            data-testid={`mark-absent-${day}`}
                            className={`text-xs px-1 py-1 rounded transition-colors ${status === "absent" ? "bg-[#B24040] text-white" : "bg-[#F2EFE9] text-[#5A615C] hover:bg-[#FAEDED]"}`}
                          >A</button>
                        </div>
                      </div>
                    );
                  })}
                </div>

                {/* Summary */}
                <div className="mt-6 grid grid-cols-3 gap-4">
                  <div className="bg-[#E9F0EC] rounded-xl p-4 text-center">
                    <div className="text-2xl font-semibold text-[#4A6B56]" data-testid="present-count">
                      {Object.values(attendanceData).filter(v => v === "present").length}
                    </div>
                    <div className="text-xs uppercase tracking-[0.15em] font-semibold text-[#4A6B56]">Present</div>
                  </div>
                  <div className="bg-[#FDF4E6] rounded-xl p-4 text-center">
                    <div className="text-2xl font-semibold text-[#D99C3D]" data-testid="halfday-count">
                      {Object.values(attendanceData).filter(v => v === "half_day").length}
                    </div>
                    <div className="text-xs uppercase tracking-[0.15em] font-semibold text-[#D99C3D]">Half Day</div>
                  </div>
                  <div className="bg-[#FAEDED] rounded-xl p-4 text-center">
                    <div className="text-2xl font-semibold text-[#B24040]" data-testid="absent-count">
                      {Object.values(attendanceData).filter(v => v === "absent").length}
                    </div>
                    <div className="text-xs uppercase tracking-[0.15em] font-semibold text-[#B24040]">Absent</div>
                  </div>
                </div>
              </div>
            )}
          </TabsContent>

          {/* ============ SALARY TAB ============ */}
          <TabsContent value="salary" data-testid="salary-section">
            <h2 className="text-2xl md:text-3xl tracking-tight font-medium text-[#2A2F2B] mb-6">Salary Management</h2>

            <div className="flex flex-wrap gap-4 mb-6 items-end">
              <div>
                <label className="text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C] mb-2 block">Month</label>
                <Select value={String(salaryMonth)} onValueChange={(v) => setSalaryMonth(parseInt(v))}>
                  <SelectTrigger data-testid="salary-month-select" className="w-[160px] bg-[#F2EFE9] border-[#E0DBD3]">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {MONTHS.map((m, i) => (
                      <SelectItem key={i} value={String(i + 1)}>{m}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div>
                <label className="text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C] mb-2 block">Year</label>
                <Select value={String(salaryYear)} onValueChange={(v) => setSalaryYear(parseInt(v))}>
                  <SelectTrigger data-testid="salary-year-select" className="w-[120px] bg-[#F2EFE9] border-[#E0DBD3]">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {[2025, 2026, 2027].map(y => (
                      <SelectItem key={y} value={String(y)}>{y}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div>
                <label className="text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C] mb-2 block">Working Days</label>
                <Input
                  type="number" value={workingDays} onChange={(e) => setWorkingDays(parseInt(e.target.value) || 0)}
                  data-testid="working-days-input" className="w-[120px] bg-[#F2EFE9] border-[#E0DBD3]"
                />
              </div>

              <Button onClick={generateAllSalaries} data-testid="generate-all-salary-btn"
                className="min-h-[48px] bg-[#C25934] hover:bg-[#A84C2B] text-white rounded-md font-semibold">
                <DollarSign className="w-4 h-4 mr-2" />Generate All Salaries
              </Button>
            </div>

            <div className="bg-white border border-[#E0DBD3] rounded-xl overflow-hidden shadow-[0_4px_12px_rgba(42,47,43,0.04)]">
              <table className="w-full">
                <thead className="bg-[#F2EFE9]">
                  <tr>
                    <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">Staff</th>
                    <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">Type</th>
                    <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">Base</th>
                    <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">Present</th>
                    <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">Half Days</th>
                    <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">Working Days</th>
                    <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">Calculated</th>
                    <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">Action</th>
                  </tr>
                </thead>
                <tbody>
                  {staff.length === 0 ? (
                    <tr><td colSpan="8" className="text-center py-12 text-[#5A615C]">Add staff members first</td></tr>
                  ) : staff.map(s => {
                    const record = salaryRecords.find(r => r.staff_id === s.id);
                    return (
                      <tr key={s.id} className="border-t border-[#E0DBD3]" data-testid={`salary-row-${s.id}`}>
                        <td className="p-4 font-semibold text-[#2A2F2B]">{s.name}</td>
                        <td className="p-4">
                          <span className={`px-3 py-1 rounded-md text-xs font-semibold uppercase tracking-[0.15em] ${s.salary_type === "monthly" ? "bg-[#E9F0EC] text-[#4A6B56]" : "bg-[#FDF4E6] text-[#D99C3D]"}`}>
                            {s.salary_type}
                          </span>
                        </td>
                        <td className="p-4 text-[#5A615C]">₹{s.salary_amount.toLocaleString()}</td>
                        <td className="p-4 text-[#5A615C]">{record ? record.days_present : "-"}</td>
                        <td className="p-4 text-[#5A615C]">{record ? record.half_days : "-"}</td>
                        <td className="p-4 text-[#5A615C]">{record ? record.total_working_days : "-"}</td>
                        <td className="p-4 font-semibold text-[#C25934]">
                          {record ? `₹${record.calculated_salary.toLocaleString()}` : "-"}
                        </td>
                        <td className="p-4">
                          <Button onClick={() => generateSalary(s.id)} data-testid={`generate-salary-${s.id}`}
                            className="bg-[#4A6B56] hover:bg-[#3D5647] text-white text-xs px-3 py-1 rounded-md">
                            Generate
                          </Button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </TabsContent>
        </Tabs>
      </div>

      {/* Staff Dialog */}
      <Dialog open={showStaffDialog} onOpenChange={setShowStaffDialog}>
        <DialogContent className="max-w-md bg-white rounded-2xl" data-testid="staff-dialog">
          <DialogHeader>
            <DialogTitle className="text-2xl tracking-tight font-medium text-[#2A2F2B]">
              {editingStaff ? "Edit Staff" : "Add Staff"}
            </DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <label className="text-sm font-semibold text-[#2A2F2B] mb-2 block">Name</label>
              <Input value={staffForm.name} onChange={(e) => setStaffForm({...staffForm, name: e.target.value})}
                data-testid="staff-name-input" className="bg-[#F2EFE9] border-[#E0DBD3]" placeholder="Full name" />
            </div>
            <div>
              <label className="text-sm font-semibold text-[#2A2F2B] mb-2 block">Role</label>
              <Select value={staffForm.role} onValueChange={(v) => setStaffForm({...staffForm, role: v})}>
                <SelectTrigger data-testid="staff-role-select" className="bg-[#F2EFE9] border-[#E0DBD3]">
                  <SelectValue placeholder="Select role" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Chef">Chef</SelectItem>
                  <SelectItem value="Waiter">Waiter</SelectItem>
                  <SelectItem value="Captain">Captain</SelectItem>
                  <SelectItem value="Cashier">Cashier</SelectItem>
                  <SelectItem value="Helper">Helper</SelectItem>
                  <SelectItem value="Manager">Manager</SelectItem>
                  <SelectItem value="Cleaner">Cleaner</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div>
              <label className="text-sm font-semibold text-[#2A2F2B] mb-2 block">Phone</label>
              <Input value={staffForm.phone} onChange={(e) => setStaffForm({...staffForm, phone: e.target.value})}
                data-testid="staff-phone-input" className="bg-[#F2EFE9] border-[#E0DBD3]" placeholder="Phone number" />
            </div>
            <div>
              <label className="text-sm font-semibold text-[#2A2F2B] mb-2 block">Salary Type</label>
              <Select value={staffForm.salary_type} onValueChange={(v) => setStaffForm({...staffForm, salary_type: v})}>
                <SelectTrigger data-testid="staff-salary-type-select" className="bg-[#F2EFE9] border-[#E0DBD3]">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="monthly">Monthly (Fixed)</SelectItem>
                  <SelectItem value="daily">Daily Wage</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div>
              <label className="text-sm font-semibold text-[#2A2F2B] mb-2 block">
                {staffForm.salary_type === "monthly" ? "Monthly Salary (₹)" : "Daily Wage (₹)"}
              </label>
              <Input type="number" value={staffForm.salary_amount} onChange={(e) => setStaffForm({...staffForm, salary_amount: parseFloat(e.target.value) || 0})}
                data-testid="staff-salary-input" className="bg-[#F2EFE9] border-[#E0DBD3]" />
            </div>
            <Button onClick={handleSaveStaff} data-testid="save-staff-btn"
              className="w-full min-h-[56px] bg-[#C25934] hover:bg-[#A84C2B] text-white rounded-md text-base font-semibold">
              {editingStaff ? "Update Staff" : "Add Staff"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default OwnerDashboard;
