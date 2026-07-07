
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Textarea } from "@/components/ui/textarea";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Mail, MessageSquare, Bell, Send } from "lucide-react";

export default function Notifications() {
  return (
    <>
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Card className="hover-lift">
            <CardContent className="p-6">
              <div className="flex items-center gap-4">
                <div className="p-3 bg-primary/20 text-primary rounded-lg">
                  <Mail className="h-6 w-6" />
                </div>
                <div>
                  <p className="text-2xl font-bold">12</p>
                  <p className="text-sm text-muted-foreground">Email Templates</p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card className="hover-lift">
            <CardContent className="p-6">
              <div className="flex items-center gap-4">
                <div className="p-3 bg-warning/20 text-warning rounded-lg">
                  <MessageSquare className="h-6 w-6" />
                </div>
                <div>
                  <p className="text-2xl font-bold">8</p>
                  <p className="text-sm text-muted-foreground">SMS Templates</p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card className="hover-lift">
            <CardContent className="p-6">
              <div className="flex items-center gap-4">
                <div className="p-3 bg-success/20 text-success rounded-lg">
                  <Bell className="h-6 w-6" />
                </div>
                <div>
                  <p className="text-2xl font-bold">5</p>
                  <p className="text-sm text-muted-foreground">In-App Alerts</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        <Tabs defaultValue="email" className="w-full">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="email">Email Templates</TabsTrigger>
            <TabsTrigger value="sms">SMS Templates</TabsTrigger>
            <TabsTrigger value="push">In-App Notifications</TabsTrigger>
          </TabsList>

          <TabsContent value="email" className="space-y-4">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
              <Card>
                <CardHeader>
                  <CardTitle className="text-base flex items-center justify-between">
                    <span>Certificate Expiry Reminder</span>
                    <Switch defaultChecked />
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="space-y-2">
                    <Label>Subject Line</Label>
                    <Input defaultValue="Your Food Certificate is Expiring Soon" />
                  </div>
                  <div className="space-y-2">
                    <Label>Message Body</Label>
                    <Textarea
                      rows={6}
                      defaultValue="Hi {{restaurant_name}},&#10;&#10;Your food certificate expires on {{expiry_date}}. Please renew to continue serving meals.&#10;&#10;Best regards,&#10;ResQBox Team"
                    />
                  </div>
                  <div className="flex gap-2">
                    <Button variant="outline" className="flex-1">
                      <Send className="mr-2 h-4 w-4" />
                      Test Send
                    </Button>
                    <Button className="flex-1 bg-success hover:bg-success/90">Save Changes</Button>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-base flex items-center justify-between">
                    <span>Order Confirmation</span>
                    <Switch defaultChecked />
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="space-y-2">
                    <Label>Subject Line</Label>
                    <Input defaultValue="Order Confirmed - {{order_id}}" />
                  </div>
                  <div className="space-y-2">
                    <Label>Message Body</Label>
                    <Textarea
                      rows={6}
                      defaultValue="Hi {{customer_name}},&#10;&#10;Your order {{order_id}} has been confirmed!&#10;Total: {{order_amount}}&#10;&#10;Thank you for saving food with us! 💚"
                    />
                  </div>
                  <div className="flex gap-2">
                    <Button variant="outline" className="flex-1">
                      <Send className="mr-2 h-4 w-4" />
                      Test Send
                    </Button>
                    <Button className="flex-1 bg-success hover:bg-success/90">Save Changes</Button>
                  </div>
                </CardContent>
              </Card>
            </div>
          </TabsContent>

          <TabsContent value="sms" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="text-base">SMS Template Editor</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-muted-foreground">
                  SMS templates will be available here. Keep messages under 160 characters for optimal delivery.
                </p>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="push" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="text-base">In-App Notification Settings</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-muted-foreground">
                  Configure in-app notification triggers and content.
                </p>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </>
  );
}
